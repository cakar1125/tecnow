import 'package:sqflite/sqflite.dart';

import '../local/schema.dart';

final class ReadHistoryEntry {
  const ReadHistoryEntry({
    required this.id,
    required this.itemId,
    required this.readAt,
    this.kind,
  });

  final int id;
  final String itemId;
  final String? kind;
  final DateTime readAt;
}

abstract interface class ReadHistoryRepository {
  Future<void> record(String itemId, String? kind);

  Future<List<ReadHistoryEntry>> readRecent({int limit = 50});

  Future<void> clear();
}

final class SqfliteReadHistoryRepository implements ReadHistoryRepository {
  SqfliteReadHistoryRepository(this._database);

  final Database _database;

  /// Bir içeriği okundu olarak işaretler.
  ///
  /// Aynı içerik **tek satır** tutar: yeniden okumak zamanı günceller, yeni
  /// kayıt eklemez. Öncesinde aynı içeriği elli kez açmak elli satır
  /// üretiyordu — hem yer harcıyor hem de geçmişi anlamsız kılıyordu.
  /// Tekillik v3'te benzersiz indeksle veritabanında zorlanıyor.
  @override
  Future<void> record(String itemId, String? kind) async {
    await _database.insert(ReadHistoryTable.name, {
      ReadHistoryTable.itemId: itemId,
      ReadHistoryTable.itemKind: kind,
      ReadHistoryTable.readAt: DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _prune();
  }

  /// Geçmişi [LocalSchema.readHistoryLimit] kayıtta tutar.
  ///
  /// Tekilleştirme tek başına yetmez: yeterince farklı içerik okuyan bir
  /// kullanıcıda tablo yine sınırsız büyürdü. Budama olmadan büyümenin
  /// durduğu bir nokta yok.
  Future<void> _prune() async {
    await _database.rawDelete(
      'DELETE FROM ${ReadHistoryTable.name} '
      'WHERE ${ReadHistoryTable.id} NOT IN ('
      '  SELECT ${ReadHistoryTable.id} FROM ${ReadHistoryTable.name}'
      '  ORDER BY ${ReadHistoryTable.readAt} DESC, ${ReadHistoryTable.id} DESC'
      '  LIMIT ?'
      ')',
      [LocalSchema.readHistoryLimit],
    );
  }

  @override
  Future<List<ReadHistoryEntry>> readRecent({int limit = 50}) async {
    if (limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'must not be negative');
    }
    final rows = await _database.query(
      ReadHistoryTable.name,
      orderBy: '${ReadHistoryTable.readAt} DESC, ${ReadHistoryTable.id} DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> clear() async {
    await _database.delete(ReadHistoryTable.name);
  }

  ReadHistoryEntry _fromRow(Map<String, Object?> row) {
    return ReadHistoryEntry(
      id: row[ReadHistoryTable.id]! as int,
      itemId: row[ReadHistoryTable.itemId]! as String,
      kind: row[ReadHistoryTable.itemKind] as String?,
      readAt: DateTime.fromMillisecondsSinceEpoch(
        row[ReadHistoryTable.readAt]! as int,
      ),
    );
  }
}
