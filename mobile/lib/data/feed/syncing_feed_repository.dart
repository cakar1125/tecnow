/// Paketlenmiş dosya, yerel önbellek ve uzak adres arasındaki karar katmanı.
///
/// Üç kopya vardır ve hangisinin gösterileceği tek bir kurala bağlıdır:
/// **üretim tarihi en yeni olan kazanır.** Kural tersine çevrilseydi
/// (önbellek her zaman kazansaydı), yeni bir sürüm yükleyen kullanıcı
/// aylar önce çekilmiş bir feed'i görmeye devam ederdi.
library;

import 'dart:convert';

import 'feed_cache.dart';
import 'feed_http_client.dart';
import 'feed_repository.dart';
import 'feed_schema.dart';

/// Bu süre geçtikten sonra içerik "bayat" sayılır ve açılışta bir tazeleme
/// denenir. Üretici günde birkaç kez çalıştığı için daha sık denemek yalnız
/// pil ve veri harcar.
const feedStaleAfter = Duration(hours: 12);

final class SyncingFeedRepository implements FeedRepository {
  SyncingFeedRepository({
    required this.bundled,
    required this.cache,
    required this.client,
    required this.endpoints,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FeedRepository bundled;
  final FeedCache cache;
  final FeedHttpClient client;

  /// Denenecek adresler, sırayla. Boşsa ağ tazelemesi kapalıdır
  /// (bkz. `feed_endpoint.dart`).
  ///
  /// Birden fazlaysa ilki birincil, kalanı yedektir: birincil çöktüğünde
  /// sıradaki denenir. Yedeğin varlık sebebi barındırıcı arızası değil,
  /// **alan adının kaybı** — o durumda DNS çevrilemez ve yeni adres
  /// duyurulamaz, çünkü duyurunun yapılacağı adres de ölmüştür.
  final List<Uri> endpoints;

  /// Testlerin zamanı sabitleyebilmesi için. "12 saat önce senkronize edildi"
  /// davranışı gerçek saat beklenerek ölçülemez.
  final DateTime Function() _clock;

  @override
  bool get remoteEnabled => endpoints.isNotEmpty;

  /// Gösterilecek içerik. Ağa **çıkmaz**.
  ///
  /// Paketlenmiş dosya her zaman okunur: hem yedek hem de karşılaştırma
  /// tabanıdır. Okunamazsa istisna yukarı gider ve arayüz "içerik okunamadı"
  /// der — o noktada gösterilecek hiçbir şey kalmamıştır.
  @override
  Future<Feed> load() async {
    final packaged = await bundled.load();
    final cached = await _readUsableCache();
    if (cached == null) return packaged;

    // Eşitlik paketlenmiş dosyaya gider: aynı içeriğin iki kopyası varsa
    // ayrıştırılmış olanı yeniden ayrıştırmanın anlamı yok.
    if (!cached.generatedAt.isAfter(packaged.generatedAt)) return packaged;
    return cached;
  }

  @override
  Future<DateTime?> lastSyncAt() async {
    final entry = await cache.read();
    if (entry == null || !_isKnownOrigin(entry)) return null;
    return entry.fetchedAt;
  }

  /// Açılışta tazeleme denemeye değer mi.
  ///
  /// Uzak adres yoksa `false`: tazelenemeyen bir içerik bayat sayılmaz,
  /// yoksa arayüz kullanıcıya çözemeyeceği bir sorun bildirirdi.
  @override
  Future<bool> isStale({Duration after = feedStaleAfter}) async {
    if (endpoints.isEmpty) return false;
    final last = await lastSyncAt();
    if (last == null) return true;
    return _clock().difference(last) >= after;
  }

  /// Adresleri **sırayla** dener; ilk başarılı olan kazanır.
  ///
  /// Başarısızlık sayılan ve sıradakine geçilen durumlar: ağ/TLS/DNS hatası,
  /// `2xx` dışı yanıt, bozuk gövde ve elde kopya yokken gelen `304`. Bunların
  /// hepsinde "bu adresten içerik alınamadı" doğrudur ve yedeğin denenmesi
  /// gerekir.
  ///
  /// Hepsi başarısızsa **birincilin** hatası bildirilir: kullanıcıya
  /// gösterilen tek satırda kanonik adresin durumu, yedeğinkinden daha
  /// anlamlıdır.
  @override
  Future<FeedSyncOutcome> refresh() async {
    if (endpoints.isEmpty) return FeedSyncOutcome.disabled;

    final cached = await cache.read();
    FeedSyncOutcome? firstFailure;

    for (final url in endpoints) {
      final outcome = await _refreshFrom(url, cached);
      if (outcome.status != FeedSyncStatus.failed) return outcome;
      firstFailure ??= outcome;
    }

    return firstFailure!;
  }

  Future<FeedSyncOutcome> _refreshFrom(Uri url, CachedFeed? cached) async {
    // Elde **tam olarak bu adrese** ait bir kopya varsa istek koşullu gider.
    // Başka bir adrese ait kopyanın doğrulayıcısını göndermek, başka bir
    // dosyanın kimliğiyle soru sormak olurdu: ayna aynı içeriği yayımlıyorsa
    // yanlış bir `304` alınabilir ve gövdesiz bir yanıt kopya sanılırdı.
    final usable = cached != null && cached.sourceUrl == url.toString()
        ? cached
        : null;

    final FeedHttpResponse response;
    try {
      response = await client.get(url, validators: usable?.validators);
    } on FeedTransportException catch (error) {
      return FeedSyncOutcome.failed(error.message);
    }

    // İçerik değişmemiş. Gövde yok, ayrıştıracak bir şey de yok: elimizdeki
    // kopya geçerliliğini koruyor ve **kontrol edildiği an** güncelleniyor.
    //
    // Ölçüldü (2026-07-28, gerçek sunucularda): `pages.github.com` ve
    // `microsoft.github.io` `If-None-Match` ile `304 Not Modified` döndü.
    // Bu dal olmasaydı değişmeyen içerik için her tazelemede 33 KB inerdi.
    if (response.isNotModified) {
      // Elde kopya yokken 304 gelemez — ama gelirse (aracı önbellek, bozuk
      // sunucu) gösterilecek bir şey olmadığı için hata sayılır.
      if (usable == null) {
        return FeedSyncOutcome.failed(
          'Sunucu içerik göndermedi ve yerel kopya yok',
        );
      }
      final now = _clock();
      await cache.write(
        usable.touched(
          fetchedAt: now,
          etag: response.etag,
          lastModified: response.lastModified,
        ),
      );
      return FeedSyncOutcome(
        status: FeedSyncStatus.unchanged,
        feed: await _effectiveFeedOrNull(),
        syncedAt: now,
      );
    }

    if (!response.isOk) {
      return FeedSyncOutcome.failed(
        'Sunucu ${response.statusCode} yanıtı verdi',
      );
    }

    final Feed fetched;
    try {
      fetched = _parse(response.body);
    } on FeedFormatException catch (error) {
      return FeedSyncOutcome.failed(error.message);
    } on FormatException {
      return FeedSyncOutcome.failed('Gelen içerik geçerli JSON değil');
    }

    // Yazma **ayrıştırmadan sonra**: bozuk bir yanıtı önbelleğe almak,
    // çalışan bir kopyayı bozuk bir kopyayla değiştirmek olurdu.
    final now = _clock();
    await cache.write(
      CachedFeed(
        payload: response.body,
        fetchedAt: now,
        generatedAt: fetched.generatedAt,
        sourceUrl: url.toString(),
        etag: response.etag,
        lastModified: response.lastModified,
      ),
    );

    final isNew =
        usable == null || fetched.generatedAt.isAfter(usable.generatedAt);

    return FeedSyncOutcome(
      status: isNew ? FeedSyncStatus.refreshed : FeedSyncStatus.unchanged,
      feed: await _effectiveFeed(fetched),
      syncedAt: now,
    );
  }

  /// Çekilen feed değil, **etkin** feed döner: uzak kopya paketlenmiş
  /// dosyadan eskiyse (bozuk bir yayın, CDN'de takılı kalmış eski dosya)
  /// onu göstermek içeriği geriye almak olurdu.
  ///
  /// Paketlenmiş dosya okunamıyorsa karşılaştırma yapılamaz ama başarılı bir
  /// tazeleme yine de başarılıdır: yeni çekilen kopya elde kalan tek geçerli
  /// içeriktir. İstisnanın buradan yukarı çıkması, bozuk bir varlık yüzünden
  /// **çalışan** bir tazelemeyi çökerten bir yol açardı.
  Future<Feed> _effectiveFeed(Feed fetched) async {
    try {
      return await load();
    } on Object {
      return fetched;
    }
  }

  /// `304` yolunda etkin feed. Çekilmiş yeni bir kopya olmadığı için geri
  /// düşülecek bir şey yok: okuma başarısız olursa `null` döner ve arayüz
  /// zaten gösterdiği içeriği göstermeye devam eder.
  Future<Feed?> _effectiveFeedOrNull() async {
    try {
      return await load();
    } on Object {
      return null;
    }
  }

  /// Yalnız **yapılandırılmış adreslerden birine ait** ve ayrıştırılabilen bir
  /// önbellek kullanılır.
  Future<Feed?> _readUsableCache() async {
    final entry = await cache.read();
    if (entry == null) return null;

    // Adres yapılandırmadan çıktıysa (ya da bu sürümde hiç yoksa) eski kopya
    // artık başka bir yayının içeriğidir; sessizce göstermek yanlış kaynağı
    // göstermektir.
    //
    // Ölçüt "şu an denenen adres" **değil**, "tanınan adreslerden biri":
    // birincil çöküp yedeğe düşüldüğünde ikisi de aynı feed'i yayımlıyor ve
    // elde sağlam bir kopya varken paketlenmiş eski dosyaya düşmek içeriği
    // geriye almak olurdu.
    if (!_isKnownOrigin(entry)) return null;

    try {
      return _parse(entry.payload);
    } on FeedFormatException {
      // Kendini onarır: bozuk satır silinmezse her açılışta yeniden
      // ayrıştırılmaya çalışılır ve önbellek kalıcı olarak ölü kalırdı.
      await cache.clear();
      return null;
    } on FormatException {
      await cache.clear();
      return null;
    }
  }

  bool _isKnownOrigin(CachedFeed entry) =>
      endpoints.any((url) => url.toString() == entry.sourceUrl);

  static Feed _parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FeedFormatException('Feed dosyası bir nesne değil');
    }
    return Feed.fromJson(decoded.cast<String, Object?>());
  }
}
