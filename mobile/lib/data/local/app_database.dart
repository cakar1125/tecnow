import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

abstract final class AppDatabase {
  static Future<Database> open({String? path, DatabaseFactory? factory}) async {
    final selectedFactory = factory ?? databaseFactory;
    final databasePath =
        path ??
        p.join(
          await selectedFactory.getDatabasesPath(),
          LocalSchema.databaseName,
        );

    return selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: LocalSchema.version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await LocalSchema.createLatest(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          for (var target = oldVersion + 1; target <= newVersion; target++) {
            await LocalSchema.upgradeTo(db, target);
          }
        },
      ),
    );
  }

  static Future<void> deleteAllLocalData(Database db) async {
    await db.transaction((transaction) async {
      for (final table in LocalTables.deletionOrder) {
        await transaction.delete(table);
      }
    });
  }
}
