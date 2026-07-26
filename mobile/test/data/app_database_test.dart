import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:teknoakis/data/local/app_database.dart';
import 'package:teknoakis/data/local/schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('v1 şeması yedi tablonun tamamını oluşturur', () async {
    final rows = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final tableNames = rows
        .map((row) => row['name']! as String)
        .where(LocalTables.all.contains)
        .toSet();

    expect(tableNames, LocalTables.all.toSet());
  });

  test('yabancı anahtar denetimi açıktır', () async {
    final rows = await db.rawQuery('PRAGMA foreign_keys');

    expect(rows.single['foreign_keys'], 1);
  });

  test('v1 veritabanı kapatılıp açıldığında veri korunur', () async {
    await db.close();
    final databasePath = p.join(
      Directory.systemTemp.path,
      'teknoakis_migration_${DateTime.now().microsecondsSinceEpoch}.db',
    );

    try {
      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );
      await db.insert(InterestsTable.name, {
        InterestsTable.id: 'flutter',
        InterestsTable.label: 'Flutter',
        InterestsTable.createdAt: 1,
      });
      await db.close();

      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );
      final rows = await db.query(InterestsTable.name);

      expect(rows, hasLength(1));
      expect(rows.single[InterestsTable.label], 'Flutter');
      expect(await db.getVersion(), LocalSchema.version);
    } finally {
      if (db.isOpen) {
        await db.close();
      }
      await databaseFactoryFfi.deleteDatabase(databasePath);
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
    }
  });

  test('NOT NULL ve yabancı anahtar ihlalleri hata verir', () async {
    await expectLater(
      db.insert(SavedItemsTable.name, {
        SavedItemsTable.id: 'missing-kind',
        SavedItemsTable.title: 'Eksik kayıt',
        SavedItemsTable.savedAt: 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      db.insert(AssistantConversationsTable.name, {
        AssistantConversationsTable.id: 'orphan-conversation',
        AssistantConversationsTable.projectId: 'missing-project',
        AssistantConversationsTable.createdAt: 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('proje silme konuşmaları ve mesajları zincirleme siler', () async {
    await db.insert(AssistantProjectsTable.name, {
      AssistantProjectsTable.id: 'project-1',
      AssistantProjectsTable.title: 'Proje',
      AssistantProjectsTable.createdAt: 1,
      AssistantProjectsTable.updatedAt: 1,
    });
    await db.insert(AssistantConversationsTable.name, {
      AssistantConversationsTable.id: 'conversation-1',
      AssistantConversationsTable.projectId: 'project-1',
      AssistantConversationsTable.createdAt: 2,
    });
    await db.insert(AssistantMessagesTable.name, {
      AssistantMessagesTable.conversationId: 'conversation-1',
      AssistantMessagesTable.role: 'user',
      AssistantMessagesTable.content: 'Merhaba',
      AssistantMessagesTable.createdAt: 3,
    });

    await db.delete(
      AssistantProjectsTable.name,
      where: '${AssistantProjectsTable.id} = ?',
      whereArgs: ['project-1'],
    );

    expect(await _rowCount(db, AssistantProjectsTable.name), 0);
    expect(await _rowCount(db, AssistantConversationsTable.name), 0);
    expect(await _rowCount(db, AssistantMessagesTable.name), 0);
  });
}

Future<int> _rowCount(Database db, String table) async {
  // Sqflite.firstIntValue yerine doğrudan okuma: sqflite_common_ffi üzerinden
  // Sqflite yardımcı sınıfı görünmüyor, bu biçim her varyantta çalışır.
  final rows = await db.rawQuery('SELECT COUNT(*) AS row_count FROM $table');
  return (rows.first['row_count'] as int?) ?? 0;
}
