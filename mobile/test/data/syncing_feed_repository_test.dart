import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_cache.dart';
import 'package:tecos/data/feed/feed_http_client.dart';
import 'package:tecos/data/feed/feed_repository.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/data/feed/syncing_feed_repository.dart';

import '../support/test_overrides.dart';

final _endpoint = Uri.https('ornek.test', '/feed.json');

/// Yedek yayın. Bilinçli olarak **farklı bir host**: yedeğin varlık sebebi
/// birincil alan adının tamamen kaybolması, aynı alan adının altındaki başka
/// bir yol değil.
final _mirror = Uri.https('ayna.github.io', '/depo/feed.json');

/// Testlerin zamanı sabitlediği an. Ağ katmanının davranışı gerçek saat
/// beklenerek ölçülemez.
final _now = DateTime.utc(2026, 7, 27, 12);

String _payload({
  required DateTime generatedAt,
  String title = 'Uzak kayıt',
  Duration refreshAfter = feedDefaultRefreshAfter,
}) => jsonEncode(
  testFeed(
    [
      testFeedItem(
        id: '00000000000000aa',
        kind: FeedItemKind.repository,
        title: title,
      ),
    ],
    generatedAt: generatedAt,
    refreshAfter: refreshAfter,
  ).toJson(),
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

  /// Son isteğe hangi doğrulayıcıların gittiği. Koşullu isteğin gerçekten
  /// **gönderildiğini** ölçmek için: yanıtın 304 olması, isteğin koşullu
  /// olduğunu kanıtlamaz — sahte istemci onu her hâlükârda döndürürdü.
  FeedValidators? lastValidators;

  @override
  Future<FeedHttpResponse> get(Uri url, {FeedValidators? validators}) async {
    calls++;
    lastUrl = url;
    lastValidators = validators;
    if (failure case final error?) throw error;
    return response!;
  }
}

/// Adres başına farklı davranan istemci. Failover'ı ölçmek için gerekli:
/// tek yanıt döndüren [_FakeHttpClient] ile "birincil çöktü, ayna cevap
/// verdi" durumu kurulamaz.
final class _Route {
  const _Route._({this.body, this.statusCode, this.error});

  factory _Route.ok(String body) => _Route._(body: body, statusCode: 200);
  factory _Route.status(int code) => _Route._(body: '', statusCode: code);
  factory _Route.failure(Object error) => _Route._(error: error);

  final String? body;
  final int? statusCode;
  final Object? error;
}

final class _RoutingHttpClient implements FeedHttpClient {
  _RoutingHttpClient(this._routes);

  final Map<Uri, _Route> _routes;

  /// Sırasıyla istenen adresler. Sıra da ölçülüyor: yedeğin **birincilden
  /// sonra** denendiği, tersi değil.
  final urls = <Uri>[];

  final _validators = <Uri, FeedValidators?>{};

  FeedValidators? validatorsFor(Uri url) => _validators[url];

  @override
  Future<FeedHttpResponse> get(Uri url, {FeedValidators? validators}) async {
    urls.add(url);
    _validators[url] = validators;

    final route = _routes[url];
    if (route == null) {
      throw const FeedTransportException('yapılandırılmamış adres');
    }
    if (route.error case final failure?) throw failure;
    return FeedHttpResponse(statusCode: route.statusCode!, body: route.body!);
  }
}

/// Paketlenmiş dosyayı taklit eden depo.
final class _BundleStub implements FeedRepository {
  _BundleStub({
    required this.generatedAt,
    this.error,
    this.availableLanguages = const [],
  });

  final DateTime generatedAt;
  final Object? error;

  /// Paketlenmiş dosyanın dil listesi. Gerçek dosyada da var olması, dil
  /// çözümünün **ilk açılışta, hiç ağa çıkmadan** çalışmasının sebebi.
  final List<FeedLanguage> availableLanguages;

  @override
  Future<Feed> load() async {
    if (error case final failure?) throw failure;
    return testFeed(
      [
        testFeedItem(
          id: '00000000000000bb',
          kind: FeedItemKind.repository,
          title: 'Paketlenmiş kayıt',
        ),
      ],
      generatedAt: generatedAt,
      availableLanguages: availableLanguages,
    );
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
  List<Uri>? endpoints,
  DateTime? bundleGeneratedAt,
  Object? bundleError,
  String? preferredLanguage,
  String? deviceLanguage,
  List<FeedLanguage> bundleLanguages = const [],
}) => SyncingFeedRepository(
  bundled: _BundleStub(
    generatedAt: bundleGeneratedAt ?? DateTime.utc(2026, 7, 20),
    error: bundleError,
    availableLanguages: bundleLanguages,
  ),
  cache: cache,
  client: client ?? _FakeHttpClient(),
  endpoints: endpoints ?? [_endpoint],
  preferredLanguage: preferredLanguage,
  deviceLanguage: deviceLanguage,
  clock: () => _now,
);

CachedFeed _cached({
  required DateTime generatedAt,
  DateTime? fetchedAt,
  String? sourceUrl,
  String? payload,
  String? etag,
  String? lastModified,
}) => CachedFeed(
  payload: payload ?? _payload(generatedAt: generatedAt),
  fetchedAt: fetchedAt ?? DateTime.utc(2026, 7, 27, 11),
  generatedAt: generatedAt,
  sourceUrl: sourceUrl ?? _endpoint.toString(),
  etag: etag,
  lastModified: lastModified,
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
        endpoints: const [],
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
        endpoints: const [],
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

    /// Paketlenmiş dosya bozuksa karşılaştırma yapılamaz, ama başarılı bir
    /// tazeleme yine de başarılıdır. İstisnanın yukarı çıkması, bozuk bir
    /// varlık yüzünden çalışan bir tazelemeyi çökerten bir yol açardı.
    test('paketlenmiş dosya bozuksa tazeleme yine de sonuç döner', () async {
      final repository = _repository(
        cache: _MemoryCache(),
        bundleError: const FeedFormatException('bozuk paket'),
        client: _FakeHttpClient(
          response: FeedHttpResponse(
            statusCode: 200,
            body: _payload(generatedAt: DateTime.utc(2026, 7, 27, 6)),
          ),
        ),
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.refreshed);
      expect(outcome.feed!.items.single.title, 'Uzak kayıt');
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
          // Pencerenin **hemen içi**, sabite göre ifade edilir. Daha önce
          // burada `11 saat 59 dakika` yazıyordu ve 12 saatlik pencereye
          // sabitlenmişti: pencere 2026-08-06'da 15 dakikaya indirilince test
          // düştü, çünkü niyetini değil o günkü sayıyı söylüyordu.
          fetchedAt: _now.subtract(feedStaleAfter - const Duration(minutes: 1)),
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

    /// Tempo **sunucudan** yönetilebilmeli: `feedStaleAfter` derleme zamanı
    /// sabiti olarak kalsaydı, mağaza yayınından sonra aralığı değiştirmek yeni
    /// bir sürüm gerektirir ve güncellemeyen kullanıcı eski temposunda kalıcı
    /// olarak kalırdı.
    test('aralık sabitten değil feed’den okunur', () async {
      const serverInterval = Duration(hours: 1);
      // Sabite göre çoktan bayat (15 dk), sunucunun dediğine göre değil.
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 27),
          fetchedAt: _now.subtract(const Duration(minutes: 30)),
          payload: _payload(
            generatedAt: DateTime.utc(2026, 7, 27),
            refreshAfter: serverInterval,
          ),
        );

      expect(
        await _repository(cache: cache).isStale(),
        isFalse,
        reason: 'sunucu bir saat dedi; 30 dakika henüz bayat değil',
      );
    });

    test('sunucunun bildirdiği aralık dolunca bayat olur', () async {
      const serverInterval = Duration(hours: 1);
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 27),
          fetchedAt: _now.subtract(const Duration(hours: 1, minutes: 1)),
          payload: _payload(
            generatedAt: DateTime.utc(2026, 7, 27),
            refreshAfter: serverInterval,
          ),
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
        endpoints: const [],
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

  /// Koşullu istek (v4).
  ///
  /// Ölçüldü (2026-07-28, **gerçek sunucularda**): `pages.github.com` ve
  /// `microsoft.github.io` `If-None-Match` başlığına `304 Not Modified`
  /// döndü. Bu davranış olmadan, içerik değişmemiş olsa bile her tazelemede
  /// gzip'li 33 KB iniyordu.
  group('koşullu istek', () {
    test('önbellekteki doğrulayıcılar istekle birlikte gider', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          etag: '"abc123"',
          lastModified: 'Mon, 27 Jul 2026 10:00:00 GMT',
        );
      final client = _FakeHttpClient(
        response: const FeedHttpResponse(statusCode: 304, body: ''),
      );

      await _repository(cache: cache, client: client).refresh();

      expect(client.lastValidators?.etag, '"abc123"');
      expect(
        client.lastValidators?.lastModified,
        'Mon, 27 Jul 2026 10:00:00 GMT',
      );
    });

    test('önbellek yokken istek koşulsuz gider', () async {
      final client = _FakeHttpClient(
        response: FeedHttpResponse(
          statusCode: 200,
          body: _payload(generatedAt: DateTime.utc(2026, 7, 27)),
        ),
      );

      await _repository(cache: _MemoryCache(), client: client).refresh();

      expect(client.lastValidators, isNull);
    });

    /// Başka bir adrese ait kopyanın etiketiyle soru sormak, farklı bir
    /// dosyanın kimliğini kullanmaktır: sunucu "değişmedi" derse elimizdeki
    /// yanlış içeriği doğru sanardık.
    test('başka adrese ait önbelleğin doğrulayıcısı gönderilmez', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          sourceUrl: 'https://eski.test/feed.json',
          etag: '"eski-etiket"',
        );
      final client = _FakeHttpClient(
        response: FeedHttpResponse(
          statusCode: 200,
          body: _payload(generatedAt: DateTime.utc(2026, 7, 27)),
        ),
      );

      await _repository(cache: cache, client: client).refresh();

      expect(client.lastValidators, isNull);
    });

    test('304 içeriği korur ve "değişmedi" der', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          etag: '"abc123"',
        );
      final original = cache.entry!.payload;
      final client = _FakeHttpClient(
        response: const FeedHttpResponse(statusCode: 304, body: ''),
      );

      final outcome = await _repository(cache: cache, client: client).refresh();

      expect(outcome.status, FeedSyncStatus.unchanged);
      // Gövde **ezilmedi**: 304'ün boş gövdesi önbelleğe yazılsaydı içerik
      // kaybolur ve uygulama paketlenmiş dosyaya düşerdi.
      expect(cache.entry!.payload, original);
      expect(cache.entry!.generatedAt, DateTime.utc(2026, 7, 26));
    });

    test('304 son kontrol anını ilerletir', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          fetchedAt: DateTime.utc(2026, 7, 26),
          etag: '"abc123"',
        );
      final client = _FakeHttpClient(
        response: const FeedHttpResponse(statusCode: 304, body: ''),
      );

      final outcome = await _repository(cache: cache, client: client).refresh();

      // Bu ilerlemeseydi içerik kalıcı olarak "bayat" sayılır ve uygulama
      // her açılışta yeniden ağa çıkardı — tam da önlemeye çalıştığımız şey.
      expect(cache.entry!.fetchedAt, _now);
      expect(outcome.syncedAt, _now);
    });

    test('304 ile gelen yeni etiket saklanır', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          etag: '"eski"',
        );
      final client = _FakeHttpClient(
        response: const FeedHttpResponse(
          statusCode: 304,
          body: '',
          etag: '"yeni"',
        ),
      );

      await _repository(cache: cache, client: client).refresh();

      expect(cache.entry!.etag, '"yeni"');
    });

    test('200 yanıtının doğrulayıcıları önbelleğe yazılır', () async {
      final cache = _MemoryCache();
      final client = _FakeHttpClient(
        response: FeedHttpResponse(
          statusCode: 200,
          body: _payload(generatedAt: DateTime.utc(2026, 7, 27)),
          etag: '"taze"',
          lastModified: 'Tue, 28 Jul 2026 02:17:00 GMT',
        ),
      );

      await _repository(cache: cache, client: client).refresh();

      expect(cache.entry!.etag, '"taze"');
      expect(cache.entry!.lastModified, 'Tue, 28 Jul 2026 02:17:00 GMT');
    });

    /// Doğrulayıcı vermeyen sunucu da desteklenmeli — ölçüldü:
    /// `pytorch.github.io` ne `ETag` ne `Last-Modified` verdi.
    test('doğrulayıcı vermeyen sunucuda tazeleme yine çalışır', () async {
      final cache = _MemoryCache();
      final client = _FakeHttpClient(
        response: FeedHttpResponse(
          statusCode: 200,
          body: _payload(generatedAt: DateTime.utc(2026, 7, 27)),
        ),
      );

      final outcome = await _repository(cache: cache, client: client).refresh();

      expect(outcome.status, FeedSyncStatus.refreshed);
      expect(cache.entry!.etag, isNull);
      expect(cache.entry!.lastModified, isNull);
    });

    /// Elde kopya yokken 304 gelmemeli. Gelirse gösterilecek bir şey yok:
    /// sessizce "değişmedi" demek, boş bir ekranı başarı saymak olurdu.
    test('önbelleksiz gelen 304 hata sayılır', () async {
      final client = _FakeHttpClient(
        response: const FeedHttpResponse(statusCode: 304, body: ''),
      );

      final outcome = await _repository(
        cache: _MemoryCache(),
        client: client,
      ).refresh();

      expect(outcome.status, FeedSyncStatus.failed);
    });
  });

  /// Yedek adres.
  ///
  /// Kendi alan adımız barındırıcı değişimini çözüyor ama **alan adının
  /// kendisinin kaybını** çözmüyor: süresi dolarsa yayın yapılacak bir yer
  /// kalmadığı için yeni adres duyurulamaz. Derleme zamanında gömülü bir
  /// yedek, bu deliği kapatan tek şey.
  group('yedek adres', () {
    test('birincil çökünce yedekten okunur', () async {
      final client = _RoutingHttpClient({
        _endpoint: _Route.failure(
          const FeedTransportException('ad çözümlenemedi'),
        ),
        _mirror: _Route.ok(_payload(generatedAt: DateTime.utc(2026, 7, 26))),
      });
      final cache = _MemoryCache();

      final outcome = await _repository(
        cache: cache,
        client: client,
        endpoints: [_endpoint, _mirror],
      ).refresh();

      expect(outcome.status, FeedSyncStatus.refreshed);
      expect(client.urls, [_endpoint, _mirror]);
      // Yazılan kopya **gerçekten indirildiği** adresi taşımalı, yoksa bir
      // sonraki koşullu istek yanlış origin'e gider.
      expect(cache.entry!.sourceUrl, _mirror.toString());
    });

    /// Doğrulayıcılar origin'e özeldir. Birincilden alınan bir `ETag` aynaya
    /// gönderilirse ayna gövdesiz bir `304` dönebilir ve elde kopya varmış
    /// gibi davranılırdı — oysa o kopya **başka bir yayının**.
    test('birincilin doğrulayıcısı yedeğe gönderilmez', () async {
      final client = _RoutingHttpClient({
        _endpoint: _Route.failure(
          const FeedTransportException('bağlanılamadı'),
        ),
        _mirror: _Route.ok(_payload(generatedAt: DateTime.utc(2026, 7, 26))),
      });
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 25),
          sourceUrl: _endpoint.toString(),
          etag: 'W/"birincil"',
        );

      await _repository(
        cache: cache,
        client: client,
        endpoints: [_endpoint, _mirror],
      ).refresh();

      expect(client.validatorsFor(_endpoint)?.etag, 'W/"birincil"');
      expect(client.validatorsFor(_mirror), isNull);
    });

    /// Ayna **aynı** feed'i yayımlıyor. Failover sırasında önbelleği "başka
    /// bir yayının içeriği" sayıp atmak, elde sağlam kopya varken paketlenmiş
    /// eski dosyaya düşmek olurdu.
    test('failover önbellekteki kopyayı atmaz', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          sourceUrl: _mirror.toString(),
        );

      final repository = _repository(
        cache: cache,
        client: _RoutingHttpClient(const {}),
        endpoints: [_endpoint, _mirror],
        bundleGeneratedAt: DateTime.utc(2026, 7, 20),
      );

      // Kopya aynadan geldi, şu an birincil yapılandırılmış durumda — yine de
      // gösterilmeli ve senkron zamanı bilinmeli.
      expect((await repository.load()).items.single.title, 'Uzak kayıt');
      expect(await repository.lastSyncAt(), isNotNull);
    });

    test('hepsi çökerse paketlenmiş içerik kalır ve hata bildirilir', () async {
      final client = _RoutingHttpClient({
        _endpoint: _Route.failure(const FeedTransportException('birincil ölü')),
        _mirror: _Route.failure(const FeedTransportException('ayna ölü')),
      });
      final repository = _repository(
        cache: _MemoryCache(),
        client: client,
        endpoints: [_endpoint, _mirror],
      );

      final outcome = await repository.refresh();

      expect(outcome.status, FeedSyncStatus.failed);
      // Bildirilen hata **birincilin**: kullanıcıya gösterilen tek satırda
      // kanonik adresin durumu daha anlamlı.
      expect(outcome.failure, contains('birincil ölü'));
      expect(client.urls, [_endpoint, _mirror]);
      expect((await repository.load()).items.single.title, 'Paketlenmiş kayıt');
    });

    /// Yedek yalnız birincil **başarısızken** denenir; başarılı bir koşuda
    /// ikinci istek atmak boşuna veri harcamak olurdu.
    test('birincil çalışıyorsa yedeğe hiç gidilmez', () async {
      final client = _RoutingHttpClient({
        _endpoint: _Route.ok(_payload(generatedAt: DateTime.utc(2026, 7, 26))),
        _mirror: _Route.ok(_payload(generatedAt: DateTime.utc(2026, 7, 26))),
      });

      await _repository(
        cache: _MemoryCache(),
        client: client,
        endpoints: [_endpoint, _mirror],
      ).refresh();

      expect(client.urls, [_endpoint]);
    });

    /// `2xx` dışı yanıt da failover sebebidir: ölçüt "bağlantı kuruldu mu"
    /// değil, "içerik alındı mı".
    test('birincilin 500 yanıtı yedeğe geçirir', () async {
      final client = _RoutingHttpClient({
        _endpoint: _Route.status(500),
        _mirror: _Route.ok(_payload(generatedAt: DateTime.utc(2026, 7, 26))),
      });

      final outcome = await _repository(
        cache: _MemoryCache(),
        client: client,
        endpoints: [_endpoint, _mirror],
      ).refresh();

      expect(outcome.status, FeedSyncStatus.refreshed);
      expect(client.urls, [_endpoint, _mirror]);
    });

    /// Bozuk gövde de failover sebebidir: birincil ayakta ama çöp yayımlıyorsa
    /// aynadaki sağlam dosya kullanılabilir.
    test('birincilin bozuk gövdesi yedeğe geçirir', () async {
      final client = _RoutingHttpClient({
        _endpoint: _Route.ok('{bozuk'),
        _mirror: _Route.ok(_payload(generatedAt: DateTime.utc(2026, 7, 26))),
      });

      final outcome = await _repository(
        cache: _MemoryCache(),
        client: client,
        endpoints: [_endpoint, _mirror],
      ).refresh();

      expect(outcome.status, FeedSyncStatus.refreshed);
      expect(client.urls, [_endpoint, _mirror]);
    });
  });

  /// İçerik dili — adres çözümü.
  ///
  /// Ölçülen sözleşme: dil dosyalarının adresi **yayından** okunuyor ve
  /// bunun için fazladan bir istek atılmıyor.
  group('içerik dili', () {
    const languages = [
      FeedLanguage(code: 'tr', url: 'feed.json'),
      FeedLanguage(code: 'en', url: 'feed.en.json'),
    ];
    final english = Uri.https('ornek.test', '/feed.en.json');

    _RoutingHttpClient routing() => _RoutingHttpClient({
      _endpoint: _Route.ok(_payload(generatedAt: DateTime.utc(2026, 7, 26))),
      english: _Route.ok(
        _payload(generatedAt: DateTime.utc(2026, 7, 26), title: 'Remote item'),
      ),
    });

    test('dil seçilmemişse taban adres istenir', () async {
      final client = routing();
      await _repository(
        cache: _MemoryCache(),
        client: client,
        bundleLanguages: languages,
      ).refresh();

      expect(client.urls, [_endpoint]);
    });

    /// Fazladan istek **yok**: liste paketlenmiş dosyadan okunuyor. Alternatif
    /// tasarım (önce varsayılanı indir, listeyi oku, sonra doğrusunu indir)
    /// her tazelemede iki tam indirme demekti.
    test('seçilen dilin adresi tek istekte çözülür', () async {
      final client = routing();
      await _repository(
        cache: _MemoryCache(),
        client: client,
        bundleLanguages: languages,
        preferredLanguage: 'en',
      ).refresh();

      expect(client.urls, [english]);
    });

    test('seçim yoksa cihazın dili kullanılır', () async {
      final client = routing();
      await _repository(
        cache: _MemoryCache(),
        client: client,
        bundleLanguages: languages,
        deviceLanguage: 'en',
      ).refresh();

      expect(client.urls, [english]);
    });

    /// Kullanıcının açık seçimi cihazı ezer: Almanya'da yaşayan biri cihazını
    /// Almanca kullanıp içeriği Türkçe okumak isteyebilir.
    test('açık seçim cihaz dilini ezer', () async {
      final client = routing();
      await _repository(
        cache: _MemoryCache(),
        client: client,
        bundleLanguages: languages,
        preferredLanguage: 'tr',
        deviceLanguage: 'en',
      ).refresh();

      expect(client.urls, [_endpoint]);
    });

    /// Sunulmayan bir dil sessizce taban adrese düşer. Kullanıcı yanlış dilde
    /// de olsa içerik görür; boş ekran görmez.
    test('sunulmayan dil taban adrese düşer', () async {
      final client = routing();
      await _repository(
        cache: _MemoryCache(),
        client: client,
        bundleLanguages: languages,
        deviceLanguage: 'ja',
      ).refresh();

      expect(client.urls, [_endpoint]);
    });

    /// Elde okunabilir kopya yoksa (paketlenmiş dosya da bozuksa) çözüm
    /// yapılamaz ama tazeleme **yine denenir**.
    test('kopya okunamıyorsa taban adres denenir', () async {
      final client = routing();
      await _repository(
        cache: _MemoryCache(),
        client: client,
        bundleError: const FeedFormatException('bozuk'),
        preferredLanguage: 'en',
      ).refresh();

      expect(client.urls, [_endpoint]);
    });

    /// Kapı 2026-08-12'de bu yüzden genişledi: `feed.en.json` adresi
    /// `endpoints` listesinde yok ve tam adres eşleşmesi arayan eski kural
    /// indirilen İngilizce kopyayı **hiç göstermezdi** — dili değiştiren
    /// kullanıcı her açılışta paketlenmiş Türkçe dosyaya geri düşerdi.
    test('dil dosyasından gelen önbellek kullanılır', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          sourceUrl: english.toString(),
        );

      final repository = _repository(
        cache: cache,
        bundleGeneratedAt: DateTime.utc(2026, 7, 20),
        bundleLanguages: languages,
        preferredLanguage: 'en',
      );

      expect(await repository.lastSyncAt(), isNotNull);
      expect((await repository.load()).items.single.title, 'Uzak kayıt');
    });

    /// Genişleme dar: **başka bir konak** hâlâ yabancı. Yapılandırmadan çıkan
    /// bir adresin eski kopyası artık başka bir yayının içeriğidir.
    test('başka konaktan gelen önbellek hâlâ reddedilir', () async {
      final cache = _MemoryCache()
        ..entry = _cached(
          generatedAt: DateTime.utc(2026, 7, 26),
          sourceUrl: 'https://baska-sunucu.test/feed.json',
        );

      final repository = _repository(
        cache: cache,
        bundleGeneratedAt: DateTime.utc(2026, 7, 20),
      );

      expect(await repository.lastSyncAt(), isNull);
      expect((await repository.load()).items.single.title, 'Paketlenmiş kayıt');
    });
  });
}
