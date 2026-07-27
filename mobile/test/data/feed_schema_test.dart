import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';

FeedItem sampleItem({
  String url = 'https://github.com/ornek/depo',
  SummaryOrigin origin = SummaryOrigin.original,
  DateTime? retractedAt,
}) => FeedItem(
  id: feedItemId(Uri.parse(url)),
  kind: FeedItemKind.repository,
  title: 'ornek/depo',
  summary: 'Örnek bir depo açıklaması.',
  summaryOrigin: origin,
  sourceName: 'GitHub',
  sourceKind: FeedSourceKind.github,
  url: Uri.parse(url),
  publishedAt: DateTime.utc(2026, 7, 20),
  checkedAt: DateTime.utc(2026, 7, 27),
  language: 'en',
  trust: const TrustSignals(
    officialSource: false,
    hasLicense: true,
    recentlyUpdated: true,
    maintained: true,
    popularity: 120,
  ),
  topics: const ['dart', 'mobil'],
  retractedAt: retractedAt,
);

void main() {
  group('gidiş-dönüş', () {
    test('bir feed JSON üzerinden aynen geri okunur', () {
      final feed = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 7, 27, 9),
        items: [sampleItem()],
      );

      final decoded = Feed.fromJson(
        jsonDecode(jsonEncode(feed.toJson())) as Map<String, Object?>,
      );

      expect(decoded.schemaVersion, feedSchemaVersion);
      expect(decoded.generatedAt, feed.generatedAt);
      final item = decoded.items.single;
      expect(item.id, feed.items.single.id);
      expect(item.title, 'ornek/depo');
      expect(item.url, Uri.parse('https://github.com/ornek/depo'));
      expect(item.publishedAt, DateTime.utc(2026, 7, 20));
      expect(item.checkedAt, DateTime.utc(2026, 7, 27));
      expect(item.topics, ['dart', 'mobil']);
      expect(item.trust.popularity, 120);
    });
  });

  group('şema sürümü', () {
    test('gelecekteki bir sürüm reddedilir', () {
      expect(
        () => Feed.fromJson({
          'schemaVersion': feedSchemaVersion + 1,
          'generatedAt': '2026-07-27T09:00:00Z',
          'items': <Object?>[],
        }),
        throwsA(isA<FeedFormatException>()),
        reason: 'bilinmeyen şema sessizce yanlış ayrıştırılmamalı',
      );
    });

    test('sürüm alanı yoksa reddedilir', () {
      expect(
        () => Feed.fromJson({
          'generatedAt': '2026-07-27T09:00:00Z',
          'items': <Object?>[],
        }),
        throwsA(isA<FeedFormatException>()),
      );
    });
  });

  group('zorunlu alanlar — CONTENT_TRUST_POLICY', () {
    /// "Her içerikte orijinal URL, kaynak türü, yayın tarihi ve son kontrol
    /// zamanı tutulur."
    for (final field in ['url', 'sourceKind', 'publishedAt', 'checkedAt']) {
      test('$field olmadan kayıt okunamaz', () {
        final json = sampleItem().toJson()..remove(field);
        expect(
          () => FeedItem.fromJson(json),
          throwsA(isA<FeedFormatException>()),
        );
      });
    }

    test('göreli URL reddedilir', () {
      final json = sampleItem().toJson()..['url'] = '/ornek/depo';
      expect(
        () => FeedItem.fromJson(json),
        throwsA(isA<FeedFormatException>()),
      );
    });

    test('bilinmeyen kaynak türü reddedilir', () {
      final json = sampleItem().toJson()..['sourceKind'] = 'twitter';
      expect(
        () => FeedItem.fromJson(json),
        throwsA(isA<FeedFormatException>()),
      );
    });
  });

  group('geri çekme', () {
    /// "Yanlış içerik düzeltme/geri çekme kaydıyla yönetilir." Kayıt silinmez,
    /// görünmez olur.
    test('geri çekilen kayıt feed\'de kalır ama görünür kümede olmaz', () {
      final feed = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 7, 27),
        items: [
          sampleItem(),
          sampleItem(
            url: 'https://github.com/ornek/yanlis',
            retractedAt: DateTime.utc(2026, 7, 26),
          ),
        ],
      );

      expect(feed.items, hasLength(2));
      expect(feed.visibleItems, hasLength(1));
      expect(feed.visibleItems.single.url.path, '/ornek/depo');
    });
  });

  group('kimlik ve kanonikleştirme', () {
    test('kimlik aynı URL için her üretimde aynıdır', () {
      final first = feedItemId(Uri.parse('https://github.com/ornek/depo'));
      final second = feedItemId(Uri.parse('https://github.com/ornek/depo'));
      expect(first, second);
      expect(first, hasLength(16));
    });

    /// Kopya birleştirme buna bağlı: aynı gelişmenin farklı adresleri aynı
    /// kimliğe düşmeli.
    test(
      'izleme parametreleri, www ve sondaki eğik çizgi kimliği değiştirmez',
      () {
        final canonical = feedItemId(
          Uri.parse('https://github.com/ornek/depo'),
        );
        for (final variant in [
          'https://www.github.com/ornek/depo',
          'https://github.com/ornek/depo/',
          'https://github.com/ornek/depo?utm_source=twitter',
          'http://github.com/ornek/depo',
          'https://GitHub.com/ornek/depo',
        ]) {
          expect(
            feedItemId(Uri.parse(variant)),
            canonical,
            reason: '$variant kanonik biçime indirgenmeli',
          );
        }
      },
    );

    test('anlamlı sorgu parametresi korunur', () {
      expect(
        canonicalizeUrl(
          Uri.parse(
            'https://huggingface.co/models?search=llama&utm_medium=rss',
          ),
        ).toString(),
        'https://huggingface.co/models?search=llama',
      );
    });

    test('farklı içerikler farklı kimlik alır', () {
      expect(
        feedItemId(Uri.parse('https://github.com/ornek/depo')),
        isNot(feedItemId(Uri.parse('https://github.com/ornek/baska'))),
      );
    });
  });

  group('güven puanı', () {
    /// "Güvenilirlik yalnız popülerlik değildir." Popülerlik tek başına
    /// bakımlı, lisanslı, resmi bir kaynağı geçememeli.
    test('popülerlik tek başına düşük puan verir', () {
      const popularOnly = TrustSignals(
        officialSource: false,
        hasLicense: false,
        recentlyUpdated: false,
        maintained: false,
        popularity: 90000,
      );
      const officialMaintained = TrustSignals(
        officialSource: true,
        hasLicense: true,
        recentlyUpdated: true,
        maintained: true,
      );

      expect(popularOnly.score, 10);
      expect(officialMaintained.score, 90);
      expect(popularOnly.score, lessThan(officialMaintained.score));
    });

    test('hiçbir sinyal yoksa puan sıfırdır', () {
      const none = TrustSignals(
        officialSource: false,
        hasLicense: false,
        recentlyUpdated: false,
        maintained: false,
      );
      expect(none.score, 0);
    });
  });

  group('özet kaynağı', () {
    /// "TeknoAkış özeti, orijinal kaynaktan görsel olarak ayrılır." Arayüzün
    /// ayırabilmesi için alan gidiş-dönüşte korunmalı.
    test('özet kaynağı gidiş-dönüşte korunur', () {
      for (final origin in SummaryOrigin.values) {
        final decoded = FeedItem.fromJson(sampleItem(origin: origin).toJson());
        expect(decoded.summaryOrigin, origin);
      }
    });
  });
}
