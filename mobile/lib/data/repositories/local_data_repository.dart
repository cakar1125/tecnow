import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/schema.dart';

/// Ayarlar'da gösterilen yerel kayıt adetleri.
final class LocalDataCounts {
  const LocalDataCounts({
    required this.savedItems,
    required this.readHistory,
    required this.assistantConversations,
  });

  static const empty = LocalDataCounts(
    savedItems: 0,
    readHistory: 0,
    assistantConversations: 0,
  );

  final int savedItems;
  final int readHistory;
  final int assistantConversations;
}

abstract interface class LocalDataRepository {
  Future<void> deleteEverything();

  Future<LocalDataCounts> readCounts();
}

final class SqfliteLocalDataRepository implements LocalDataRepository {
  SqfliteLocalDataRepository(this._database);

  final Database _database;

  @override
  Future<void> deleteEverything() => AppDatabase.deleteAllLocalData(_database);

  @override
  Future<LocalDataCounts> readCounts() async => LocalDataCounts(
    savedItems: await _count(SavedItemsTable.name),
    readHistory: await _count(ReadHistoryTable.name),
    assistantConversations: await _count(AssistantConversationsTable.name),
  );

  /// `Sqflite.firstIntValue` `sqflite_common_ffi` üzerinden görünmüyor;
  /// doğrudan okuma her varyantta çalışır (bkz. TASK-0008 düzeltmesi).
  Future<int> _count(String table) async {
    final rows = await _database.rawQuery(
      'SELECT COUNT(*) AS row_count FROM $table',
    );
    return (rows.first['row_count'] as int?) ?? 0;
  }
}
