import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';

import '../../tool/feed/summarize.dart';
import '../../tool/feed/summary_guard.dart';

final _now = DateTime.utc(2026, 7, 27);

FeedItem _item({
  String title = 'Nexus-7B released',
  String summary = 'A new open-weights model with 7B parameters.',
  SummaryOrigin origin = SummaryOrigin.original,
  String language = 'en',
}) => FeedItem(
  id: 'a',
  kind: FeedItemKind.aiModel,
  title: title,
  summary: summary,
  summaryOrigin: origin,
  sourceName: 'Hugging Face',
  sourceKind: FeedSourceKind.huggingFace,
  url: Uri.parse('https://huggingface.co/a/b'),
  publishedAt: _now,
  checkedAt: _now,
  language: language,
  trust: const TrustSignals(
    officialSource: true,
    hasLicense: true,
    recentlyUpdated: true,
    maintained: true,
    popularity: 5,
  ),
  topics: const ['llm'],
);

/// Sabit bir cevap veren sahte model.
final class FakeSummarizer implements Summarizer {
  FakeSummarizer(this.reply);

  final String? reply;
  final seen = <String>[];

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
  }) async {
    seen.add(sourceText);
    return reply;
  }
}

final class ThrowingSummarizer implements Summarizer {
  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
  }) async => throw StateError('ağ hatası');
}

void main() {
  group('anahtar yokken', () {
    /// Anahtar bir kolaylıktır, koşul değil: feed anahtarsız da eksiksiz
    /// üretilmeli.
    test('hiç çağrı yapılmaz ve kayıtlar olduğu gibi kalır', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: const DisabledSummarizer());

      expect(pass.summarized, 0);
      expect(pass.items.single.summaryOrigin, SummaryOrigin.original);
      expect(
        pass.items.single.summary,
        'A new open-weights model with 7B parameters.',
      );
      expect(pass.items.single.language, 'en');
    });
  });

  group('kabul edilen özet', () {
    test('TeknoAkış özeti olarak işaretlenir ve dili Türkçe olur', () async {
      final pass = await applySummaries(
        [_item()],
        summarizer: FakeSummarizer('7B parametreli yeni açık ağırlıklı model.'),
      );

      final item = pass.items.single;
      expect(item.summary, '7B parametreli yeni açık ağırlıklı model.');
      expect(item.summaryOrigin, SummaryOrigin.teknoakis);
      expect(item.language, 'tr');
      expect(pass.summarized, 1);
    });

    /// Özet yeniden yazılabilir, gerçekler yazılamaz.
    test('kaynak, adres, tarih ve güven sinyalleri değişmez', () async {
      final original = _item();
      final pass = await applySummaries([
        original,
      ], summarizer: FakeSummarizer('7B parametreli model.'));

      final item = pass.items.single;
      expect(item.url, original.url);
      expect(item.sourceName, original.sourceName);
      expect(item.publishedAt, original.publishedAt);
      expect(item.trust.score, original.trust.score);
      expect(item.topics, original.topics);
      expect(item.id, original.id);
    });
  });

  group('doğrulama kapısı', () {
    /// Kapı tek yönlü güvenli: şüphede kalırsa reddeder ve kayıt orijinal
    /// metniyle yayımlanır. En kötü durumda İngilizce kalır, uydurulmaz.
    test('kaynakta olmayan sayı reddedilir, orijinal korunur', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer('Model ayda 20 dolara sunuluyor.'));

      final item = pass.items.single;
      expect(item.summaryOrigin, SummaryOrigin.original);
      expect(item.summary, 'A new open-weights model with 7B parameters.');
      expect(pass.summarized, 0);
      expect(pass.rejected, {SummaryRejection.unsourcedNumber: 1});
    });

    test('kaynakta olmayan bağlantı reddedilir', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer('Ayrıntı: https://uydurma.test/x'));
      expect(pass.rejected, {SummaryRejection.unsourcedLink: 1});
      expect(pass.items.single.summaryOrigin, SummaryOrigin.original);
    });

    test('çok uzun özet reddedilir', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer('çok uzun ' * 60));
      expect(pass.rejected, {SummaryRejection.tooLong: 1});
    });
  });

  group('modele verilen metin', () {
    /// Tarih ve makine alanları modele **verilmez**: tarih metne girerse izin
    /// verilen sayı havuzu genişler ve uydurulmuş bir fiyat kapıdan geçer.
    test('yalnız başlık ve kaynağın kendi açıklaması gönderilir', () async {
      final summarizer = FakeSummarizer(null);
      await applySummaries([_item()], summarizer: summarizer);

      final sent = summarizer.seen.single;
      expect(
        sent,
        'Nexus-7B released\nA new open-weights model with 7B '
        'parameters.',
      );
      expect(sent, isNot(contains('2026')), reason: 'tarih sızmamalı');
      expect(sent, isNot(contains('huggingface.co')));
    });
  });

  group('dayanıklılık', () {
    test('model hatası kaydı düşürür, koşuyu değil', () async {
      final pass = await applySummaries([
        _item(),
        _item(title: 'İkinci'),
      ], summarizer: ThrowingSummarizer());
      expect(pass.items, hasLength(2));
      expect(pass.failed, 2);
      expect(pass.summarized, 0);
    });

    test('boş cevap kaydı olduğu gibi bırakır', () async {
      final pass = await applySummaries([
        _item(),
      ], summarizer: FakeSummarizer(null));
      expect(pass.items.single.summaryOrigin, SummaryOrigin.original);
      expect(pass.rejected, isEmpty);
      expect(pass.failed, 0);
    });

    /// TeknoAkış'ın kendi kurduğu cümle zaten Türkçedir.
    test('TeknoAkış özeti yeniden özetlenmez', () async {
      final summarizer = FakeSummarizer('yeni özet');
      final pass = await applySummaries([
        _item(
          origin: SummaryOrigin.teknoakis,
          summary: 'Hugging Face üzerinde yayımlanan model.',
          language: 'tr',
        ),
      ], summarizer: summarizer);

      expect(summarizer.seen, isEmpty, reason: 'çağrı yapılmamalı');
      expect(
        pass.items.single.summary,
        'Hugging Face üzerinde yayımlanan '
        'model.',
      );
    });

    /// Maliyet kapısı: bütçe dolunca kalanlar orijinal metinleriyle kalır ve
    /// koşu **başarısız olmaz**.
    test('bütçe aşılınca kalan kayıtlar orijinal kalır', () async {
      final summarizer = FakeSummarizer('Kısa Türkçe özet.');
      final pass = await applySummaries(
        [_item(title: 'Bir'), _item(title: 'İki'), _item(title: 'Üç')],
        summarizer: summarizer,
        budget: 2,
      );

      expect(summarizer.seen, hasLength(2));
      expect(pass.summarized, 2);
      expect(pass.budgetExhausted, isTrue);
      expect(pass.items, hasLength(3));
      expect(pass.items.last.summaryOrigin, SummaryOrigin.original);
    });
  });
}
