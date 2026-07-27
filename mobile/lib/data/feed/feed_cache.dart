/// Uzaktan çekilen feed'in cihazdaki kopyası.
///
/// Çevrimdışı davranışın tamamı buraya dayanır: uygulama ağa çıkamadığında
/// en son **başarıyla** çekilen içeriği gösterir. Ağ hatası hiçbir zaman
/// içeriğin kaybolması anlamına gelmez.
library;

import 'package:sqflite/sqflite.dart';

import '../local/schema.dart';

final class CachedFeed {
  const CachedFeed({
    required this.payload,
    required this.fetchedAt,
    required this.generatedAt,
    required this.sourceUrl,
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

  @override
  Future<CachedFeed?> read() async {
    final db = await _database;
    final rows = await db.query(FeedCacheTable.name, limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.single;
    return CachedFeed(
      payload: row[FeedCacheTable.payload]! as String,
      fetchedAt: _toDate(row[FeedCacheTable.fetchedAt]! as int),
      generatedAt: _toDate(row[FeedCacheTable.generatedAt]! as int),
      sourceUrl: row[FeedCacheTable.sourceUrl]! as String,
    );
  }

  @override
  Future<void> write(CachedFeed entry) async {
    final db = await _database;
    await db.insert(FeedCacheTable.name, {
      FeedCacheTable.id: _rowId,
      FeedCacheTable.payload: entry.payload,
      FeedCacheTable.fetchedAt: entry.fetchedAt.toUtc().millisecondsSinceEpoch,
      FeedCacheTable.generatedAt: entry.generatedAt
          .toUtc()
          .millisecondsSinceEpoch,
      FeedCacheTable.sourceUrl: entry.sourceUrl,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
