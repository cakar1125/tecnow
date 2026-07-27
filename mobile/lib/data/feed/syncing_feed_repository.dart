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
    required this.endpoint,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FeedRepository bundled;
  final FeedCache cache;
  final FeedHttpClient client;

  /// `null` ise ağ tazelemesi kapalıdır (bkz. `feed_endpoint.dart`).
  final Uri? endpoint;

  /// Testlerin zamanı sabitleyebilmesi için. "12 saat önce senkronize edildi"
  /// davranışı gerçek saat beklenerek ölçülemez.
  final DateTime Function() _clock;

  @override
  bool get remoteEnabled => endpoint != null;

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
    if (entry == null || !_belongsToEndpoint(entry)) return null;
    return entry.fetchedAt;
  }

  /// Açılışta tazeleme denemeye değer mi.
  ///
  /// Uzak adres yoksa `false`: tazelenemeyen bir içerik bayat sayılmaz,
  /// yoksa arayüz kullanıcıya çözemeyeceği bir sorun bildirirdi.
  @override
  Future<bool> isStale({Duration after = feedStaleAfter}) async {
    if (endpoint == null) return false;
    final last = await lastSyncAt();
    if (last == null) return true;
    return _clock().difference(last) >= after;
  }

  @override
  Future<FeedSyncOutcome> refresh() async {
    final url = endpoint;
    if (url == null) return FeedSyncOutcome.disabled;

    final FeedHttpResponse response;
    try {
      response = await client.get(url);
    } on FeedTransportException catch (error) {
      return FeedSyncOutcome.failed(error.message);
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
    final previous = await cache.read();
    final now = _clock();
    await cache.write(
      CachedFeed(
        payload: response.body,
        fetchedAt: now,
        generatedAt: fetched.generatedAt,
        sourceUrl: url.toString(),
      ),
    );

    final isNew =
        previous == null ||
        !_belongsToEndpoint(previous) ||
        fetched.generatedAt.isAfter(previous.generatedAt);

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

  /// Yalnız **şu anki adrese ait** ve ayrıştırılabilen bir önbellek kullanılır.
  Future<Feed?> _readUsableCache() async {
    final entry = await cache.read();
    if (entry == null) return null;

    // Adres değiştiyse (ya da bu sürümde hiç yoksa) eski kopya artık başka bir
    // yayının içeriğidir; sessizce göstermek yanlış kaynağı göstermektir.
    if (!_belongsToEndpoint(entry)) return null;

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

  bool _belongsToEndpoint(CachedFeed entry) =>
      endpoint != null && entry.sourceUrl == endpoint.toString();

  static Feed _parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FeedFormatException('Feed dosyası bir nesne değil');
    }
    return Feed.fromJson(decoded.cast<String, Object?>());
  }
}
