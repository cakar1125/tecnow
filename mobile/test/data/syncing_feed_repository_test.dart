import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_cache.dart';
import 'package:teknoakis/data/feed/feed_http_client.dart';
import 'package:teknoakis/data/feed/feed_repository.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';
import 'package:teknoakis/data/feed/syncing_feed_repository.dart';

import '../support/test_overrides.dart';

final _endpoint = Uri.https('ornek.test', '/feed.json');

/// Testlerin zamanı sabitlediği an. Ağ katmanının davranışı gerçek saat
/// beklenerek ölçülemez.
final _now = DateTime.utc(2026, 7, 27, 12);

String _payload({required DateTime generatedAt, String title = 'Uzak kayıt'}) =>
    jsonEncode(
      testFeed([
        testFeedItem(
          id: '00000000000000aa',
          kind: FeedItemKind.repository,
          title: title,
        ),
      ], generatedAt: generatedAt).toJson(),
    );

/// Bellek içi önbellek. Gerçek sqflite davranışı `feed_cache_test.dart`
/// içinde ayrıca ölçülüyor; burada ölçülen **karar mantığı**.
final class _MemoryCache implements FeedCache {
  CachedFeed? entry;
  int clearCount = 0;

  @override
  Future<CachedFeed?> read() async => entry;

  @override
  Future<void> write(CachedFeed value) async => entry = value;

  @override
  Future<void> clear() async {
    clearCount++;
    entry = null;
  }
}

final class _FakeHttpClient implements FeedHttpClient {
  _FakeHttpClient({this.response, this.failure});

  final FeedHttpResponse? response;
  final Object? failure;
  int calls = 0;
  Uri? lastUrl;

  @override
  Future<FeedHttpResponse> get(Uri url) async {
    calls++;
    lastUrl = url;
    if (failure case final error?) throw error;
    return response!;
  }
}

/// Paketlenmiş dosyayı taklit eden depo.
final class _BundleStub implements FeedRepository {
  _BundleStub({required this.generatedAt, this.error});

  final DateTime generatedAt;
  final Object? error;

  @override
  Future<Feed> load() async {
    if (error case final failure?) throw failure;
    return testFeed([
      testFeedItem(
        id: '00000000000000bb',
        kind: FeedItemKind.repository,
        title: 'Paketlenmiş kayıt',
      ),
    ], generatedAt: generatedAt);
  }

  @override
  Future<FeedSyncOutcome> refresh() async => FeedSyncOutcome.disabled;

  @override
  Future<DateTime?> lastSyncAt() async => null;

  @override
  Future<bool> isStale() async => false;

  @override
  bool get remoteEnabled => false;
}

SyncingFeedRepository _repository({
  required FeedCache cache,
  FeedHttpClient? client,
  Uri? endpoint,
  DateTime? bundleGeneratedAt,
  Object? bundleError,
}) => SyncingFeedRepository(
  bundled: _BundleStub(
    generatedAt: bundleGeneratedAt ?? DateTime.utc(2026, 7, 20),
    error: bundleError,
  ),
  cache: cache,
  client: client ?? _FakeHttpClient(),
  endpoint: endpoint ?? _endpoint,
  clock: () => _now,
);

CachedFeed _cached({
  required DateTime generatedAt,
  DateTime? fetchedAt,
  String? sourceUrl,
  String? payload,
}) => CachedFeed(
  payload: payload ?? _payload(generatedAt: generatedAt),
  fetchedAt: fetchedAt ?? DateTime.utc(2026, 7, 27, 11),
  generatedAt: generatedAt,
  sourceUrl: sourceUrl ?? _endpoint.toString(),
);

void main() {
  group('load — hangi kopya kazanır', () {
    test('önbellek yoksa paketlenmiş dosya gösterilir', () async {
      final feed = await _repository(cache: _MemoryCache()).load();

      expect(feed.items.single.title, 'Paketlenmiş kayıt');
    });

    test('önbellek daha yeniyse önbellek gösterilir', () async {
      final cache = _MemoryCache()
        ..entry = _cached(generatedAt: DateTime.utc(2026, 7, 26));

      final feed = await _repository(
        cache: cache,
        bundleGeneratedAt: DateTime.utc(2026, 7, 20),
      ).load();

      expect(feed.items.single.title, 'Uzak kayıt');
    });

    /// Uygulama güncellendiğinde paketlenmiş dosya aylar önce çekilmiş bir
    /// önbellekten yeni olabilir. Kural tersine çevrilseydi, yeni sürüm
    /// yükleyen kullanıcı eski içeriği görmeye devam ederdi.
    test('paketlenmiş dosya daha yeniyse o kazanır', () async {
      final cache = _MemoryCache()
        ..entry = _cached(generatedAt: DateTime.utc(2026, 5, 1));

      final feed = await _repository(
        cache: cache,
        bundleGeneratedAt: DateTime.utc(2026, 7, 20),
      ).load();

      expect(feed.items.single.title, 'Paketlenmiş kayıt');
    });

    test('eşitlikte paketlenmiş dosya kullanılır', () async {
      final same = DateTime.utc(2026, 7, 20);
      final cache = _MemoryCache()..entry = _cached(generatedAt: same);

      final feed = await _repository(
        cache: cache,
        bundleGeneratedAt: same,
      ).load();

      expect(feed.items.single.title, 'Paketlenmiş kayıt');
    });

    /// Adres değiştiyse eski kopya artık başka bir yayının içeriğidir.
    test('başka adresten gelen önbellek kullanılmaz', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          sourceUrl: 'https://eski.test/feed.json',
        );

      final feed = await _repository(cache: cache).load();

      expect(feed.items.single.title, 'Paketlenmiş kayıt');
    });

    test('uzak adres yokken önbellek kullanılmaz', () async {
      final cache = _MemoryCache()
        ..entry = _cached(generatedAt: DateTime.utc(2026, 7, 26));

      final repository = SyncingFeedRepository(
        bundled: _BundleStub(generatedAt: DateTime.utc(2026, 7, 20)),
        cache: cache,
        client: _FakeHttpClient(),
        endpoint: null,
      );

      expect((await repository.load()).items.single.title, 'Paketlenmiş kayıt');
      expect(repository.remoteEnabled, isFalse);
    });

    /// Bozuk önbellek kurtarılabilir bir durumdur (paketlenmiş dosya duruyor);
    /// bozuk **paket** değildir. Asimetri bilinçli.
    test('bozuk önbellek silinir ve paketlenmiş dosyaya düşülür', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          payload: 'bu json degil',
        );

      final feed = await _repository(cache: cache).load();

      expect(feed.items.single.title, 'Paketlenmiş kayıt');
      expect(cache.clearCount, 1, reason: 'bozuk satır silinmeli');
      expect(cache.entry, isNull);
    });

    test('bilinmeyen şema sürümlü önbellek de silinir', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          payload: jsonEncode({
            'schemaVersion': feedSchemaVersion + 1,
            'generatedAt': '2026-07-26T00:00:00.000Z',
            'items': <Object?>[],
          }),
        );

      final feed = await _repository(cache: cache).load();

      expect(feed.items.single.title, 'Paketlenmiş kayıt');
      expect(cache.clearCount, 1);
    });

    test('paketlenmiş dosya okunamazsa hata yukarı gider', () async {
      await expectLater(
        _repository(
          cache: _MemoryCache(),
          bundleError: const FeedFormatException('bozuk paket'),
        ).load(),
        throwsA(isA<FeedFormatException>()),
      );
    });
  });

  group('refresh', () {
    test('adres yoksa denenmez', () async {
      final client = _FakeHttpClient();
      final repository = SyncingFeedRepository(
        bundled: _BundleStub(generatedAt: DateTime.utc(2026, 7, 20)),
        cache: _MemoryCache(),
        client: client,
        endpoint: null,
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.disabled);
      expect(client.calls, 0, reason: 'ağa hiç çıkılmamalı');
    });

    test('yeni içerik önbelleğe yazılır ve gösterilir', () async {
      final cache = _MemoryCache();
      final repository = _repository(
        cache: cache,
        client: _FakeHttpClient(
          response: FeedHttpResponse(
            statusCode: 200,
            body: _payload(generatedAt: DateTime.utc(2026, 7, 27, 6)),
          ),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.refreshed);
      expect(outcome.syncedAt, _now);
      expect(outcome.feed!.items.single.title, 'Uzak kayıt');
      expect(cache.entry!.fetchedAt, _now);
      expect(cache.entry!.sourceUrl, _endpoint.toString());
      expect(await repository.lastSyncAt(), _now);
    });

    test('aynı içerik geldiğinde durum "değişmedi" olur', () async {
      final generatedAt = DateTime.utc(2026, 7, 27, 6);
      final cache = _MemoryCache()..entry = _cached(generatedAt: generatedAt);
      final repository = _repository(
        cache: cache,
        client: _FakeHttpClient(
          response: FeedHttpResponse(
            statusCode: 200,
            body: _payload(generatedAt: generatedAt),
          ),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.unchanged);
      expect(outcome.isSuccess, isTrue);
      // İçerik değişmese de senkronizasyon başarılıdır: "son güncelleme"
      // zamanı ilerler, yoksa arayüz saatlerdir denemiyormuş gibi görünürdü.
      expect(cache.entry!.fetchedAt, _now);
    });

    /// Uzak kopya paketlenmiş dosyadan eskiyse (bozuk bir yayın, CDN'de
    /// takılı kalmış eski dosya) onu göstermek içeriği geriye almak olurdu.
    test('uzak kopya eskiyse gösterilen içerik geriye gitmez', () async {
      final cache = _MemoryCache();
      final repository = _repository(
        cache: cache,
        bundleGeneratedAt: DateTime.utc(2026, 7, 20),
        client: _FakeHttpClient(
          response: FeedHttpResponse(
            statusCode: 200,
            body: _payload(generatedAt: DateTime.utc(2026, 5, 1)),
          ),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.refreshed);
      expect(outcome.feed!.items.single.title, 'Paketlenmiş kayıt');
      // Yine de yazılır: uçtan gelen gerçek budur, hangisinin gösterileceği
      // ayrı bir karardır.
      expect(cache.entry, isNotNull);
    });

    test('ağ hatası içeriği değiştirmez', () async {
      final cache = _MemoryCache()
        ..entry = _cached(generatedAt: DateTime.utc(2026, 7, 26));
      final repository = _repository(
        cache: cache,
        client: _FakeHttpClient(
          failure: const FeedTransportException('Bağlantı kurulamadı'),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.failed);
      expect(outcome.failure, 'Bağlantı kurulamadı');
      expect(outcome.feed, isNull);
      expect(cache.entry!.generatedAt, DateTime.utc(2026, 7, 26));
    });

    test('hata kodu başarısızlık sayılır', () async {
      final repository = _repository(
        cache: _MemoryCache(),
        client: _FakeHttpClient(
          response: const FeedHttpResponse(statusCode: 503, body: ''),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.failed);
      expect(outcome.failure, contains('503'));
    });

    /// Bozuk bir yanıtı önbelleğe almak, çalışan bir kopyayı bozuk bir
    /// kopyayla değiştirmek olurdu.
    test('bozuk yanıt önbelleği bozmaz', () async {
      final good = _cached(generatedAt: DateTime.utc(2026, 7, 26));
      final cache = _MemoryCache()..entry = good;
      final repository = _repository(
        cache: cache,
        client: _FakeHttpClient(
          response: const FeedHttpResponse(
            statusCode: 200,
            body: '<html>hata sayfasi</html>',
          ),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.failed);
      expect(cache.entry, same(good));
    });

    test('bilinmeyen şema sürümü yazılmaz', () async {
      final cache = _MemoryCache();
      final repository = _repository(
        cache: cache,
        client: _FakeHttpClient(
          response: FeedHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'schemaVersion': feedSchemaVersion + 1,
              'generatedAt': '2026-07-27T06:00:00.000Z',
              'items': <Object?>[],
            }),
          ),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.failed);
      expect(cache.entry, isNull);
    });
  });

  group('bayatlık', () {
    test('hiç senkronize edilmemişse bayattır', () async {
      expect(await _repository(cache: _MemoryCache()).isStale(), isTrue);
    });

    test('pencere dolmadan bayat sayılmaz', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 27),
          fetchedAt: _now.subtract(const Duration(hours: 11, minutes: 59)),
        );

      expect(await _repository(cache: cache).isStale(), isFalse);
    });

    test('pencere dolunca bayat olur', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 27),
          fetchedAt: _now.subtract(feedStaleAfter),
        );

      expect(await _repository(cache: cache).isStale(), isTrue);
    });

    /// Tazelenemeyen bir içerik bayat sayılmaz: arayüz kullanıcıya
    /// çözemeyeceği bir sorun bildirmemeli.
    test('uzak adres yokken bayat olmaz', () async {
      final repository = SyncingFeedRepository(
        bundled: _BundleStub(generatedAt: DateTime.utc(2026, 7, 20)),
        cache: _MemoryCache(),
        client: _FakeHttpClient(),
        endpoint: null,
        clock: () => _now,
      );

      expect(await repository.isStale(), isFalse);
    });
  });

  test('lastSyncAt yalnız şu anki adresin kaydını sayar', () async {
    final cache = _MemoryCache()
      ..entry = _cached(
        generatedAt: DateTime.utc(2026, 7, 26),
        sourceUrl: 'https://eski.test/feed.json',
      );

    expect(await _repository(cache: cache).lastSyncAt(), isNull);
  });

  test('paketlenmiş depo tazeleme vaat etmez', () async {
    final repository = FakeFeedRepository(const []);

    expect(repository.remoteEnabled, isFalse);
    expect((await repository.refresh()).status, FeedSyncStatus.disabled);
    expect(await repository.lastSyncAt(), isNull);
  });
}
