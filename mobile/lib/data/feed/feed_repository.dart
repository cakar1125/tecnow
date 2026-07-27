/// Feed okuma sözleşmesi ve paketlenmiş dosyayı okuyan gerçekleme.
///
/// İçerik derleme zamanında `tool/feed/generate.dart` ile üretilip
/// `assets/feed/feed.json` olarak pakete konur. Bu dosya salt-okunurdur;
/// uygulama onu ne yazar ne değiştirir.
///
/// Ağ tazelemesi bunun **üstüne** gelir ([SyncingFeedRepository]): paketlenmiş
/// dosya hiçbir zaman devre dışı kalmaz, en kötü durumda gösterilen içerik odur.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'feed_schema.dart';

/// Varlık okuyucu. Testler gerçek paket yerine kendi metnini verir.
typedef FeedAssetLoader = Future<String> Function(String path);

/// Bir tazeleme denemesinin sonucu.
///
/// Başarısızlık bir istisna değil, **dönen bir değer**: çevrimdışı kalmak bu
/// uygulamada beklenen bir durumdur, olağandışı bir olay değil. İstisna
/// fırlatılsaydı her çağıranın onu yakalayıp normale çevirmesi gerekirdi ve
/// bir yerde unutulduğunda ağ hatası ekranı boşaltırdı.
enum FeedSyncStatus {
  /// Yeni içerik alındı.
  refreshed,

  /// Bağlantı kuruldu ama içerik zaten günceldi.
  unchanged,

  /// Uzak adres yapılandırılmamış — ağ tazelemesi kapalı.
  disabled,

  /// Denendi, olmadı. Gösterilen içerik değişmedi.
  failed,
}

final class FeedSyncOutcome {
  const FeedSyncOutcome({
    required this.status,
    this.feed,
    this.failure,
    this.syncedAt,
  });

  static const disabled = FeedSyncOutcome(status: FeedSyncStatus.disabled);

  const FeedSyncOutcome.failed(String this.failure)
    : status = FeedSyncStatus.failed,
      feed = null,
      syncedAt = null;

  final FeedSyncStatus status;

  /// Başarıda **gösterilecek** feed. Çekilen dosyanın kendisi olmayabilir:
  /// paketlenmiş dosya daha yeniyse o kazanır (bkz. [SyncingFeedRepository]).
  final Feed? feed;

  /// Kullanıcıya gösterilebilir hata cümlesi. Teknik ayrıntı taşımaz.
  final String? failure;

  final DateTime? syncedAt;

  bool get isSuccess =>
      status == FeedSyncStatus.refreshed || status == FeedSyncStatus.unchanged;
}

abstract interface class FeedRepository {
  /// Gösterilecek içeriği verir. **Ağa çıkmaz**: açılış, ağın durumuna
  /// bakmaksızın anında içerik göstermek zorundadır.
  Future<Feed> load();

  /// Uzak adresten tazelemeyi dener.
  Future<FeedSyncOutcome> refresh();

  /// Son **başarılı** senkronizasyon anı; hiç olmadıysa `null`.
  Future<DateTime?> lastSyncAt();

  /// Uzak adres yapılandırılmış mı. Arayüz, tazeleme kontrolünü hiç
  /// göstermemek için bunu bilmek zorundadır: çalışmayacağı bilinen bir
  /// düğme koymak sahte bir işlev vaadidir.
  bool get remoteEnabled;
}

final class BundledFeedRepository implements FeedRepository {
  BundledFeedRepository({FeedAssetLoader? loader})
    : _loader = loader ?? _loadFromBundle;

  /// `pubspec.yaml` içindeki yolla birebir aynı olmalı; test bunu doğrular.
  static const assetPath = 'assets/feed/feed.json';

  final FeedAssetLoader _loader;

  /// Bozuk ya da bilinmeyen sürümlü bir dosya **sessizce yutulmaz**.
  ///
  /// `Feed.fromJson` bilmediği bir şema sürümünü reddediyor; buradan çıkan
  /// hata sağlayıcıya, oradan da arayüzün hata durumuna gider. Yanlış
  /// ayrıştırıp bozuk içerik göstermektense göstermemek doğrudur.
  @override
  Future<Feed> load() async {
    final raw = await _loader(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FeedFormatException('Feed dosyası bir nesne değil');
    }
    return Feed.fromJson(decoded.cast<String, Object?>());
  }

  /// Paketlenmiş dosya tazelenemez — sözleşmenin dürüst cevabı budur.
  @override
  Future<FeedSyncOutcome> refresh() async => FeedSyncOutcome.disabled;

  @override
  Future<DateTime?> lastSyncAt() async => null;

  @override
  bool get remoteEnabled => false;

  static Future<String> _loadFromBundle(String path) =>
      rootBundle.loadString(path);
}
