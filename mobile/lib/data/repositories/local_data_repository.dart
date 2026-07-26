import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';

abstract interface class LocalDataRepository {
  Future<void> deleteEverything();
}

final class SqfliteLocalDataRepository implements LocalDataRepository {
  SqfliteLocalDataRepository(this._database);

  final Database _database;

  @override
  Future<void> deleteEverything() => AppDatabase.deleteAllLocalData(_database);
}
