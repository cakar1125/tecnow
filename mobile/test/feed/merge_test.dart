import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';

import '../../tool/feed/merge.dart';

FeedItem item({
  required String url,
  String title = 'Nexus-7B',
  FeedItemKind kind = FeedItemKind.aiModel,
  String sourceName = 'Hugging Face',
  DateTime? publishedAt,
  bool official = false,
  bool maintained = true,
  bool license = true,
  bool recent = true,
  List<String> topics = const [],
  List<String> mergedUrls = const [],
  DateTime? retractedAt,
  String? correctionNote,
}) => FeedItem(
  id: feedItemId(Uri.parse(url)),
  kind: kind,
  title: title,
  summary: '$title özeti.',
  summaryOrigin: SummaryOrigin.original,
  sourceName: sourceName,
  sourceKind: FeedSourceKind.huggingFace,
  url: Uri.parse(url),
  publishedAt: publishedAt ?? DateTime.utc(2026, 7, 20),
  checkedAt: DateTime.utc(2026, 7, 27),
  language: 'en',
  trust: TrustSignals(
    officialSource: official,
    hasLicense: license,
    recentlyUpdated: recent,
    maintained: maintained,
  ),
  topics: topics,
  mergedUrls: mergedUrls.map(Uri.parse).toList(),
  retractedAt: retractedAt,
  correctionNote: correctionNote,
);

void main() {
  group('URL kopyaları', () {
    test('aynı kanonik adres tek kayda iner', () {
      final merged = mergeDuplicates([
        item(url: 'https://huggingface.co/nexus/Nexus-7B'),
        item(url: 'https://huggingface.co/nexus/Nexus-7B/?utm_source=rss'),
        item(url: 'https://www.huggingface.co/nexus/Nexus-7B'),
      ]);

      expect(merged, hasLength(1));
      expect(
        merged.single.mergedUrls,
        isEmpty,
        reason: 'hepsi aynı kanonik adres; ek kaynak yok',
      );
    });
  });

  group('kaynaklar arası kopyalar', () {
    test('aynı tür ve aynı başlık birleştirilir', () {
      final merged = mergeDuplicates([
        item(url: 'https://huggingface.co/nexus/Nexus-7B'),
        item(
          url: 'https://openai.com/blog/nexus-7b',
          title: 'nexus 7b',
          sourceName: 'OpenAI Blog',
          official: true,
        ),
      ]);

      expect(merged, hasLength(1));
      expect(
        merged.single.sourceName,
        'OpenAI Blog',
        reason: 'resmi kaynak daha yüksek güven puanı alır ve kazanır',
      );
      expect(
        merged.single.mergedUrls.map((url) => url.host),
        ['huggingface.co'],
        reason: 'kaybeden adres şeffaflık için saklanmalı',
      );
    });

    test('farklı tür birleştirilmez', () {
      final merged = mergeDuplicates([
        item(url: 'https://huggingface.co/nexus/Nexus-7B'),
        item(
          url: 'https://github.com/nexus/nexus-7b',
          kind: FeedItemKind.repository,
        ),
      ]);
      expect(merged, hasLength(2));
    });

    /// Bulanık eşleştirme bilinçli olarak yok: yanlış birleştirme bir
    /// gelişmeyi tamamen gizler.
    test('benzer ama farklı başlıklar birleştirilmez', () {
      final merged = mergeDuplicates([
        item(url: 'https://huggingface.co/a/Nexus-7B', title: 'Nexus-7B'),
        item(url: 'https://huggingface.co/a/Nexus-13B', title: 'Nexus-13B'),
        item(
          url: 'https://huggingface.co/a/Nexus-7B-Instruct',
          title: 'Nexus-7B Instruct',
        ),
      ]);
      expect(merged, hasLength(3));
    });

    test('noktalama ve büyük harf farkı birleştirmeyi engellemez', () {
      final merged = mergeDuplicates([
        item(url: 'https://huggingface.co/a/x', title: 'Nexus-7B Released!'),
        item(url: 'https://openai.com/blog/x', title: 'nexus 7b   released'),
      ]);
      expect(merged, hasLength(1));
    });
  });

  group('kazanan seçimi', () {
    test('güven puanı yüksek olan kazanır', () {
      final merged = mergeDuplicates([
        item(
          url: 'https://huggingface.co/a/x',
          maintained: false,
          license: false,
        ),
        item(url: 'https://openai.com/blog/x', official: true),
      ]);
      expect(merged.single.url.host, 'openai.com');
    });

    test('puan eşitse erken yayın tarihi kazanır', () {
      final merged = mergeDuplicates([
        item(
          url: 'https://huggingface.co/a/x',
          publishedAt: DateTime.utc(2026, 7, 22),
        ),
        item(
          url: 'https://github.com/a/x',
          publishedAt: DateTime.utc(2026, 7, 20),
        ),
      ]);
      expect(
        merged.single.url.host,
        'github.com',
        reason: 'orijinal duyuru, aktarımına yeğlenir',
      );
    });
  });

  group('birleştirme kayıtları', () {
    test('etiketler birleşir', () {
      final merged = mergeDuplicates([
        item(url: 'https://huggingface.co/a/x', topics: ['llm']),
        item(
          url: 'https://openai.com/blog/x',
          official: true,
          topics: ['llm', 'open-weights'],
        ),
      ]);
      expect(merged.single.topics.toSet(), {'llm', 'open-weights'});
    });

    test('önceki birleştirmelerin adresleri korunur', () {
      final merged = mergeDuplicates([
        item(
          url: 'https://huggingface.co/a/x',
          mergedUrls: ['https://mistral.ai/blog/x'],
        ),
        item(url: 'https://openai.com/blog/x', official: true),
      ]);
      expect(merged.single.mergedUrls.map((url) => url.host).toSet(), {
        'huggingface.co',
        'mistral.ai',
      });
    });

    test('kazananın kendi adresi mergedUrls içine girmez', () {
      final merged = mergeDuplicates([
        item(url: 'https://openai.com/blog/x', official: true),
        item(url: 'https://openai.com/blog/x/?utm_source=rss', official: true),
      ]);
      expect(merged.single.mergedUrls, isEmpty);
    });
  });

  group('geri çekme', () {
    /// Güvenli yön: kopyalardan biri geri çekilmişse birleşik kayıt da
    /// gösterilmez.
    test('kopyalardan biri geri çekilmişse birleşik kayıt geri çekilir', () {
      final merged = mergeDuplicates([
        item(url: 'https://openai.com/blog/x', official: true),
        item(
          url: 'https://huggingface.co/a/x',
          retractedAt: DateTime.utc(2026, 7, 26),
          correctionNote: 'Kaynak geri çekti.',
        ),
      ]);
      expect(merged.single.isRetracted, isTrue);
      expect(merged.single.correctionNote, 'Kaynak geri çekti.');
    });
  });

  group('belirlenimcilik', () {
    /// Üretici her koşuda aynı dosyayı yazmalı, yoksa her cron çalışmasında
    /// anlamsız bir değişiklik commit'lenir.
    test('girdi sırası çıktıyı değiştirmez', () {
      final items = [
        item(
          url: 'https://openai.com/blog/a',
          title: 'A',
          publishedAt: DateTime.utc(2026, 7, 20),
        ),
        item(
          url: 'https://huggingface.co/b',
          title: 'B',
          publishedAt: DateTime.utc(2026, 7, 25),
        ),
        item(
          url: 'https://github.com/c',
          title: 'C',
          publishedAt: DateTime.utc(2026, 7, 22),
        ),
      ];

      final forward = mergeDuplicates(items).map((i) => i.title).toList();
      final backward = mergeDuplicates(
        items.reversed.toList(),
      ).map((i) => i.title).toList();

      expect(forward, backward);
      expect(forward, ['B', 'C', 'A'], reason: 'yeniden eskiye sıralanmalı');
    });
  });

  test('boş liste boş sonuç verir', () {
    expect(mergeDuplicates([]), isEmpty);
  });
}
