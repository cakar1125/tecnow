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

  @override
  Future<void> record(String itemId, String? kind) async {
    await _database.insert(ReadHistoryTable.name, {
      ReadHistoryTable.itemId: itemId,
      ReadHistoryTable.itemKind: kind,
      ReadHistoryTable.readAt: DateTime.now().millisecondsSinceEpoch,
    });
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
