/// Paketlenmiş feed'i okur.
///
/// Uygulamada **ağ yok**: içerik derleme zamanında `tool/feed/generate.dart`
/// ile üretilip `assets/feed/feed.json` olarak pakete konur. Bu dosya
/// salt-okunurdur; uygulama onu ne yazar ne değiştirir.
///
/// Ağ üzerinden tazeleme ayrı bir paketin işi (TASK-0016). O geldiğinde bu
/// arayüz aynı kalır ve yalnız kaynağı değişir — bu yüzden yükleyici
/// enjekte edilebilir.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'feed_schema.dart';

/// Varlık okuyucu. Testler gerçek paket yerine kendi metnini verir.
typedef FeedAssetLoader = Future<String> Function(String path);

abstract interface class FeedRepository {
  Future<Feed> load();
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

  static Future<String> _loadFromBundle(String path) =>
      rootBundle.loadString(path);
}
