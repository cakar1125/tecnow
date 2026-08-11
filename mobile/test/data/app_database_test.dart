import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tecos/data/local/app_database.dart';
import 'package:tecos/data/local/schema.dart';
import 'package:tecos/data/repositories/read_history_repository.dart';

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

  test('kurulum şemadaki bütün tabloları oluşturur', () async {
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
      'tecos_migration_${DateTime.now().microsecondsSinceEpoch}.db',
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

  /// Migration iskeleti TASK-0008'de yazıldı ama v2'ye kadar hiç çalışmadı.
  /// Yükseltme yolu ilk kez burada ölçüldü: kurulu bir uygulamanın verisi
  /// güncellemeden sağ çıkmazsa bu ancak kullanıcıda görünürdü.
  group('v1 → güncel sürüme yükseltme', () {
    late String databasePath;

    setUp(() async {
      await db.close();
      databasePath = p.join(
        Directory.systemTemp.path,
        'tecos_v1_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final legacy = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, _) => LocalSchema.createV1(database),
        ),
      );
      await legacy.insert(SavedItemsTable.name, {
        SavedItemsTable.id: 'eski-kayit',
        SavedItemsTable.kind: 'repository',
        SavedItemsTable.title: 'Yükseltmeden önce kaydedildi',
        SavedItemsTable.savedAt: 1,
      });
      // v1'de aynı içerik birden çok satır üretebiliyordu; v3 migration'ı
      // benzersiz indeksi kurabilmek için önce bunları temizlemek zorunda.
      for (var readAt = 1; readAt <= 3; readAt++) {
        await legacy.insert(ReadHistoryTable.name, {
          ReadHistoryTable.itemId: 'ayni-icerik',
          ReadHistoryTable.itemKind: 'repository',
          ReadHistoryTable.readAt: readAt,
        });
      }
      await legacy.close();
    });

    tearDown(() async {
      if (db.isOpen) await db.close();
      await databaseFactoryFfi.deleteDatabase(databasePath);
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
    });

    test('kullanıcı verisi korunur ve sürüm yükselir', () async {
      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );

      expect(await db.getVersion(), LocalSchema.version);
      final rows = await db.query(SavedItemsTable.name);
      expect(rows, hasLength(1));
      expect(
        rows.single[SavedItemsTable.title],
        'Yükseltmeden önce kaydedildi',
      );
    });

    /// v3 benzersiz indeksi kuramadan önce var olan kopyaları temizlemek
    /// zorunda; temizlemeseydi migration hata verir ve uygulama güncellemeden
    /// sonra **hiç açılmazdı**.
    test('geçmişteki kopyalar temizlenir, en yenisi kalır', () async {
      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );

      final rows = await db.query(ReadHistoryTable.name);
      expect(rows, hasLength(1));
      expect(rows.single[ReadHistoryTable.readAt], 3, reason: 'en yenisi');
    });

    test('yükseltmeden sonra aynı içerik ikinci satır açmaz', () async {
      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );
      final history = SqfliteReadHistoryRepository(db);

      await history.record('ayni-icerik', 'repository');
      await history.record('ayni-icerik', 'repository');

      expect(await _rowCount(db, ReadHistoryTable.name), 1);
    });

    test('v2 tablosu yükseltmeden sonra yazılabilir', () async {
      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );

      await db.insert(FeedCacheTable.name, {
        FeedCacheTable.id: 1,
        FeedCacheTable.payload: '{}',
        FeedCacheTable.fetchedAt: 1,
        FeedCacheTable.generatedAt: 1,
        FeedCacheTable.sourceUrl: 'https://ornek.test/feed.json',
      });

      expect(await db.query(FeedCacheTable.name), hasLength(1));
    });

    /// Sıfırdan kurulan cihaz ile yükseltilen cihaz **aynı** şemaya varmalı.
    /// İki ayrı yol olsaydı aradaki fark ancak birinde bozuk bir sorgu
    /// olarak görünürdü.
    test('yükseltilen şema, sıfırdan kurulanla aynı', () async {
      final upgraded = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );
      final upgradedObjects = await _schemaObjects(upgraded);
      await upgraded.close();

      final fresh = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final freshObjects = await _schemaObjects(fresh);
      await fresh.close();

      expect(upgradedObjects, freshObjects);
    });
  });

  /// v3 → v4: önbellek satırı **korunmalı**.
  ///
  /// v3 migration'ı `feed_cache` tablosunu düşürüp yeniden kuruyordu ve bu
  /// meşruydu: gövde biçimi değiştiği için var olan satır zaten okunamazdı.
  /// v4'te durum farklı — satır geçerli ve gövdesi 33 KB. Aynı kısayolu
  /// almak, güncelleme yükleyen her kullanıcıyı gereksiz bir indirmeye
  /// sokardı. Bu yüzden `ALTER TABLE ... ADD COLUMN` kullanılıyor ve test
  /// satırın sağ çıktığını ölçüyor.
  group('v3 → v4 yükseltmesi', () {
    late String databasePath;

    setUp(() async {
      await db.close();
      databasePath = p.join(
        Directory.systemTemp.path,
        'tecos_v3_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final legacy = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (database, _) async {
            await LocalSchema.createV1(database);
            await LocalSchema.upgradeTo(database, 2);
            await LocalSchema.upgradeTo(database, 3);
          },
        ),
      );
      await legacy.insert(FeedCacheTable.name, {
        FeedCacheTable.id: 1,
        FeedCacheTable.payload: Uint8List.fromList([1, 2, 3]),
        FeedCacheTable.fetchedAt: 111,
        FeedCacheTable.generatedAt: 222,
        FeedCacheTable.sourceUrl: 'https://ornek.test/feed.json',
      });
      await legacy.close();
    });

    tearDown(() async {
      if (db.isOpen) await db.close();
      await databaseFactoryFfi.deleteDatabase(databasePath);
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
    });

    test('önbellek satırı korunur ve doğrulayıcılar boş gelir', () async {
      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );

      expect(await db.getVersion(), LocalSchema.version);
      final rows = await db.query(FeedCacheTable.name);
      expect(rows, hasLength(1), reason: 'önbellek satırı atılmamalı');
      expect(
        rows.single[FeedCacheTable.sourceUrl],
        'https://ornek.test/feed.json',
      );
      // İlk istek koşulsuz gider; doğrulayıcılar o yanıttan dolar.
      expect(rows.single[FeedCacheTable.etag], isNull);
      expect(rows.single[FeedCacheTable.lastModified], isNull);
    });

    test('yükseltmeden sonra doğrulayıcılar yazılabilir', () async {
      db = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );

      await db.update(FeedCacheTable.name, {
        FeedCacheTable.etag: '"abc123"',
        FeedCacheTable.lastModified: 'Mon, 27 Jul 2026 10:00:00 GMT',
      });

      final row = (await db.query(FeedCacheTable.name)).single;
      expect(row[FeedCacheTable.etag], '"abc123"');
    });

    test('v3\'ten yükseltilen şema, sıfırdan kurulanla aynı', () async {
      final upgraded = await AppDatabase.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );
      final upgradedObjects = await _schemaObjects(upgraded);
      await upgraded.close();

      final fresh = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final freshObjects = await _schemaObjects(fresh);
      await fresh.close();

      expect(upgradedObjects, freshObjects);
    });
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

/// Tablo ve indeks tanımları. `sqlite_master.sql` metni karşılaştırıldığı için
/// yalnız adlar değil sütunlar ve kısıtlar da kapsanır.
Future<Set<String>> _schemaObjects(Database db) async {
  final rows = await db.query(
    'sqlite_master',
    columns: ['sql'],
    where: 'sql IS NOT NULL AND name NOT LIKE ?',
    whereArgs: ['sqlite_%'],
  );
  return rows.map((row) => row['sql']! as String).toSet();
}

Future<int> _rowCount(Database db, String table) async {
  // Sqflite.firstIntValue yerine doğrudan okuma: sqflite_common_ffi üzerinden
  // Sqflite yardımcı sınıfı görünmüyor, bu biçim her varyantta çalışır.
  final rows = await db.rawQuery('SELECT COUNT(*) AS row_count FROM $table');
  return (rows.first['row_count'] as int?) ?? 0;
}
