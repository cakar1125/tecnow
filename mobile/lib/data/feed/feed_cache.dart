/// Uzaktan çekilen feed'in cihazdaki kopyası.
///
/// Çevrimdışı davranışın tamamı buraya dayanır: uygulama ağa çıkamadığında
/// en son **başarıyla** çekilen içeriği gösterir. Ağ hatası hiçbir zaman
/// içeriğin kaybolması anlamına gelmez.
library;

import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../local/schema.dart';
import 'feed_http_client.dart' show FeedValidators;

final class CachedFeed {
  const CachedFeed({
    required this.payload,
    required this.fetchedAt,
    required this.generatedAt,
    required this.sourceUrl,
    this.etag,
    this.lastModified,
  });

  /// Ham JSON metni.
  final String payload;

  /// Çekmenin başarıyla tamamlandığı an — arayüzdeki "son güncelleme" budur.
  final DateTime fetchedAt;

  /// Feed'in üretildiği an. Paketlenmiş dosyayla karşılaştırmak için ayrıca
  /// tutulur ([payload] içinde de vardır ama oraya bakmak ayrıştırma ister).
  final DateTime generatedAt;

  /// Hangi adresten geldiği.
  final String sourceUrl;

  /// Sunucunun bu kopya için verdiği doğrulayıcılar (v4). Bir sonraki istekte
  /// koşullu başlık olarak geri gönderilir.
  final String? etag;
  final String? lastModified;

  FeedValidators get validators =>
      FeedValidators(etag: etag, lastModified: lastModified);

  /// Aynı gövde, güncellenen çekme anı ve doğrulayıcılar.
  ///
  /// `304` yanıtında kullanılıyor: içerik değişmedi ama **kontrol edildiği an**
  /// değişti. Bu ayrım olmadan bir `304`, "hiç senkronize olmadı" gibi
  /// görünür ve uygulama her açılışta yeniden denerdi.
  CachedFeed touched({
    required DateTime fetchedAt,
    String? etag,
    String? lastModified,
  }) => CachedFeed(
    payload: payload,
    fetchedAt: fetchedAt,
    generatedAt: generatedAt,
    sourceUrl: sourceUrl,
    etag: etag ?? this.etag,
    lastModified: lastModified ?? this.lastModified,
  );
}

abstract interface class FeedCache {
  Future<CachedFeed?> read();

  Future<void> write(CachedFeed entry);

  Future<void> clear();
}

final class SqfliteFeedCache implements FeedCache {
  /// Veritabanını **future olarak** alır.
  ///
  /// Böylece önbellek nesnesi eşzamanlı kurulabilir ve `feedRepositoryProvider`
  /// senkron bir `Provider` olarak kalır; `FutureProvider`'a çevrilseydi feed'i
  /// okuyan her ekran ve her test, veritabanı açılışını da beklemek zorunda
  /// kalırdı.
  SqfliteFeedCache(this._database);

  final Future<Database> _database;

  static const _rowId = 1;

  /// Okunamayan bir satır **silinir** ve `null` dönülür.
  ///
  /// Kendini onarır: bozuk bir kayıt silinmezse her açılışta yeniden çözülmeye
  /// çalışılır ve önbellek kalıcı olarak ölü kalırdı. Kayıp yok — önbellek
  /// tanımı gereği atılabilir, uygulama paketlenmiş dosyaya düşer ve ilk
  /// tazelemede yeniden dolar.
  @override
  Future<CachedFeed?> read() async {
    final db = await _database;
    final rows = await db.query(FeedCacheTable.name, limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.single;
    final String payload;
    try {
      payload = _decode(row[FeedCacheTable.payload]);
    } on Object {
      await clear();
      return null;
    }

    return CachedFeed(
      payload: payload,
      fetchedAt: _toDate(row[FeedCacheTable.fetchedAt]! as int),
      generatedAt: _toDate(row[FeedCacheTable.generatedAt]! as int),
      sourceUrl: row[FeedCacheTable.sourceUrl]! as String,
      etag: row[FeedCacheTable.etag] as String?,
      lastModified: row[FeedCacheTable.lastModified] as String?,
    );
  }

  @override
  Future<void> write(CachedFeed entry) async {
    final db = await _database;
    await db.insert(FeedCacheTable.name, {
      FeedCacheTable.id: _rowId,
      FeedCacheTable.payload: _encode(entry.payload),
      FeedCacheTable.fetchedAt: entry.fetchedAt.toUtc().millisecondsSinceEpoch,
      FeedCacheTable.generatedAt: entry.generatedAt
          .toUtc()
          .millisecondsSinceEpoch,
      FeedCacheTable.sourceUrl: entry.sourceUrl,
      FeedCacheTable.etag: entry.etag,
      FeedCacheTable.lastModified: entry.lastModified,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Gövde **sıkıştırılmış** saklanır.
  ///
  /// Ölçüldü (2026-07-28): 200 kayıtlık feed ham 182,8 KB, gzip 30,5 KB —
  /// %83,3 küçülme. JSON çok tekrarlı olduğu için kazanç büyük; feed
  /// büyüdükçe de büyür.
  static Uint8List _encode(String payload) =>
      Uint8List.fromList(gzip.encode(utf8.encode(payload)));

  static String _decode(Object? value) {
    if (value is! List<int>) {
      throw const FormatException('Önbellek gövdesi ikili veri değil');
    }
    return utf8.decode(gzip.decode(value));
  }

  @override
  Future<void> clear() async {
    final db = await _database;
    await db.delete(FeedCacheTable.name);
  }

  /// Tarihler UTC olarak yazılır ve UTC olarak okunur. Yerel saat dilimine
  /// çevrilseydi, cihazın saat dilimi değiştiğinde "son güncelleme" saatleri
  /// kayardı.
  static DateTime _toDate(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}
