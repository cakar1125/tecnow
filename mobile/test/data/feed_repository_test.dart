import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_repository.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:yaml/yaml.dart' show loadYaml;

String _feedJson({
  int schemaVersion = feedSchemaVersion,
  List<Map<String, Object?>> items = const [],
}) => jsonEncode({
  'schemaVersion': schemaVersion,
  'generatedAt': '2026-07-27T00:00:00.000Z',
  'items': items,
});

Map<String, Object?> _item({String id = 'a', String? retractedAt}) => {
  'id': id,
  'kind': 'repository',
  'title': 'Bir depo',
  'summary': 'Bir açıklama.',
  'summaryOrigin': 'original',
  'sourceName': 'GitHub',
  'sourceKind': 'github',
  'url': 'https://github.com/a/$id',
  'publishedAt': '2026-07-20T00:00:00.000Z',
  'checkedAt': '2026-07-27T00:00:00.000Z',
  'language': 'en',
  'trust': {
    'officialSource': true,
    'hasLicense': true,
    'recentlyUpdated': true,
    'maintained': true,
  },
  'retractedAt': ?retractedAt,
};

BundledFeedRepository _repository(String body) =>
    BundledFeedRepository(loader: (_) async => body);

void main() {
  group('paketlenmiş dosyayı okuma', () {
    test('kayıtlar sözleşmeye göre çözülür', () async {
      final feed = await _repository(_feedJson(items: [_item()])).load();

      expect(feed.schemaVersion, feedSchemaVersion);
      expect(feed.items.single.title, 'Bir depo');
      expect(feed.generatedAt, DateTime.utc(2026, 7, 27));
    });

    /// Politika düzeltmeyi **kayıtla** yönetmeyi şart koşuyor: geri çekilen
    /// içerik gösterilmez ama dosyadan silinmez.
    test('geri çekilmiş kayıt görünür kümede değildir', () async {
      final feed = await _repository(
        _feedJson(
          items: [
            _item(),
            _item(id: 'b', retractedAt: '2026-07-26T00:00:00.000Z'),
          ],
        ),
      ).load();

      expect(feed.items, hasLength(2), reason: 'dosyada durmaya devam eder');
      expect(feed.visibleItems.map((item) => item.id), ['a']);
    });
  });

  group('bozuk dosya', () {
    /// Yanlış ayrıştırıp bozuk içerik göstermektense göstermemek doğrudur.
    test('bilinmeyen şema sürümü reddedilir', () {
      expect(
        () =>
            _repository(_feedJson(schemaVersion: feedSchemaVersion + 1)).load(),
        throwsA(isA<FeedFormatException>()),
      );
    });

    test('JSON olmayan içerik reddedilir', () {
      expect(
        () => _repository('bu JSON değil').load(),
        throwsA(isA<FormatException>()),
      );
    });

    test('nesne olmayan gövde reddedilir', () {
      expect(
        () => _repository('[]').load(),
        throwsA(isA<FeedFormatException>()),
      );
    });
  });

  group('pakete konan gerçek dosya', () {
    /// En değerli test bu: üretici bozuk bir dosya yazarsa ya da şema
    /// değişirse burada patlar — cihazda boş ekran olarak değil.
    test('gerçekten ayrıştırılıyor ve boş değil', () async {
      final body = File(BundledFeedRepository.assetPath).readAsStringSync();
      final feed = await _repository(body).load();

      expect(feed.items, isNotEmpty);
      expect(feed.schemaVersion, feedSchemaVersion);
      for (final item in feed.items) {
        expect(item.summary.trim(), isNotEmpty, reason: '${item.id} özetsiz');
        expect(item.url.scheme, 'https');
        expect(item.id, matches(RegExp(r'^[0-9a-f]{16}$')));
      }
    });

    test('kayıt kimlikleri tekil', () async {
      final body = File(BundledFeedRepository.assetPath).readAsStringSync();
      final feed = await _repository(body).load();
      final ids = feed.items.map((item) => item.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    /// Yol uyuşmazlığı ancak cihazda boş ekran olarak görünürdü.
    test('pubspec ile aynı yolu gösteriyor', () {
      final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
      final assets = ((pubspec['flutter'] as Map)['assets'] as List)
          .map((asset) => '$asset')
          .toList();
      expect(assets, contains(BundledFeedRepository.assetPath));
    });
  });
}
