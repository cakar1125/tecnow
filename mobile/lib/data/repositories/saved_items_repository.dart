import 'package:sqflite/sqflite.dart';

import '../local/schema.dart';

final class SavedItem {
  const SavedItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.savedAt,
    this.sourceLabel,
    this.summary,
  });

  final String id;
  final String kind;
  final String title;
  final String? sourceLabel;
  final String? summary;
  final DateTime savedAt;
}

abstract interface class SavedItemsRepository {
  Future<List<SavedItem>> readAll();

  Future<void> add(SavedItem item);

  Future<void> removeById(String id);

  Future<void> clear();
}

final class SqfliteSavedItemsRepository implements SavedItemsRepository {
  SqfliteSavedItemsRepository(this._database);

  final Database _database;

  @override
  Future<List<SavedItem>> readAll() async {
    final rows = await _database.query(
      SavedItemsTable.name,
      orderBy: '${SavedItemsTable.savedAt} DESC, ${SavedItemsTable.id} ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> add(SavedItem item) async {
    await _database.insert(SavedItemsTable.name, {
      SavedItemsTable.id: item.id,
      SavedItemsTable.kind: item.kind,
      SavedItemsTable.title: item.title,
      SavedItemsTable.sourceLabel: item.sourceLabel,
      SavedItemsTable.summary: item.summary,
      SavedItemsTable.savedAt: item.savedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> removeById(String id) async {
    await _database.delete(
      SavedItemsTable.name,
      where: '${SavedItemsTable.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clear() async {
    await _database.delete(SavedItemsTable.name);
  }

  SavedItem _fromRow(Map<String, Object?> row) {
    return SavedItem(
      id: row[SavedItemsTable.id]! as String,
      kind: row[SavedItemsTable.kind]! as String,
      title: row[SavedItemsTable.title]! as String,
      sourceLabel: row[SavedItemsTable.sourceLabel] as String?,
      summary: row[SavedItemsTable.summary] as String?,
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        row[SavedItemsTable.savedAt]! as int,
      ),
    );
  }
}
