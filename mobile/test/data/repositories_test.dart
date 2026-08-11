import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tecos/data/local/app_database.dart';
import 'package:tecos/data/local/schema.dart';
import 'package:tecos/data/repositories/interests_repository.dart';
import 'package:tecos/data/repositories/local_data_repository.dart';
import 'package:tecos/data/repositories/read_history_repository.dart';
import 'package:tecos/data/repositories/saved_items_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SqfliteInterestsRepository interestsRepository;
  late SqfliteSavedItemsRepository savedItemsRepository;
  late SqfliteReadHistoryRepository readHistoryRepository;
  late SqfliteLocalDataRepository localDataRepository;

  setUp(() async {
    db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    interestsRepository = SqfliteInterestsRepository(db);
    savedItemsRepository = SqfliteSavedItemsRepository(db);
    readHistoryRepository = SqfliteReadHistoryRepository(db);
    localDataRepository = SqfliteLocalDataRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('ilgi alanları replaceAll ve readAll ile gidiş-dönüş yapar', () async {
    await interestsRepository.replaceAll(['Yapay Zekâ', 'Flutter']);

    expect(await interestsRepository.readAll(), ['Yapay Zekâ', 'Flutter']);
  });

  test('kaydedilen öğe eklenir, okunur ve id ile silinir', () async {
    final savedAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    await savedItemsRepository.add(
      SavedItem(
        id: 'item-1',
        kind: 'article',
        title: 'Yerel veri',
        sourceLabel: 'tecOS',
        summary: 'SQLite temeli',
        savedAt: savedAt,
      ),
    );

    final items = await savedItemsRepository.readAll();
    expect(items, hasLength(1));
    expect(items.single.id, 'item-1');
    expect(items.single.kind, 'article');
    expect(items.single.title, 'Yerel veri');
    expect(items.single.sourceLabel, 'tecOS');
    expect(items.single.summary, 'SQLite temeli');
    expect(items.single.savedAt, savedAt);

    await savedItemsRepository.removeById('item-1');
    expect(await savedItemsRepository.readAll(), isEmpty);
  });

  test('aynı id ile ikinci add kaydı çoğaltmaz', () async {
    await savedItemsRepository.add(
      SavedItem(
        id: 'item-1',
        kind: 'article',
        title: 'İlk başlık',
        savedAt: DateTime.fromMillisecondsSinceEpoch(1),
      ),
    );
    await savedItemsRepository.add(
      SavedItem(
        id: 'item-1',
        kind: 'article',
        title: 'Güncel başlık',
        savedAt: DateTime.fromMillisecondsSinceEpoch(2),
      ),
    );

    final items = await savedItemsRepository.readAll();
    expect(items, hasLength(1));
    expect(items.single.title, 'Güncel başlık');
  });

  test('okuma geçmişi en yeni kayıt önce olacak şekilde döner', () async {
    await readHistoryRepository.record('item-1', 'article');
    await readHistoryRepository.record('item-2', 'repository');

    final entries = await readHistoryRepository.readRecent(limit: 2);

    expect(entries.map((entry) => entry.itemId), ['item-2', 'item-1']);
    expect(entries.map((entry) => entry.kind), ['repository', 'article']);
  });

  group('okuma geçmişi sınırlı', () {
    /// Aynı içeriği elli kez açmak elli satır üretiyordu: hem yer harcıyor
    /// hem de "okuma geçmişi" olarak anlamsız bir liste veriyordu.
    test('aynı içerik tek satır tutar, zamanı güncellenir', () async {
      await readHistoryRepository.record('item-1', 'repository');
      await readHistoryRepository.record('item-1', 'repository');
      await readHistoryRepository.record('item-1', 'repository');

      expect(await _rowCount(db, ReadHistoryTable.name), 1);
      expect(await readHistoryRepository.readRecent(), hasLength(1));
    });

    test('farklı içerikler ayrı satırlarda durur', () async {
      await readHistoryRepository.record('item-1', 'repository');
      await readHistoryRepository.record('item-2', 'aiModel');

      expect(await _rowCount(db, ReadHistoryTable.name), 2);
    });

    /// Tekilleştirme tek başına yetmez: yeterince farklı içerik okuyan bir
    /// kullanıcıda tablo yine sınırsız büyürdü.
    test('sınır aşılınca en eskiler budanır', () async {
      for (var index = 0; index < LocalSchema.readHistoryLimit + 25; index++) {
        await readHistoryRepository.record('item-$index', 'repository');
      }

      expect(
        await _rowCount(db, ReadHistoryTable.name),
        LocalSchema.readHistoryLimit,
      );

      // Kalanlar **en yeniler** olmalı; budama en eskiden başlar.
      final newest = await readHistoryRepository.readRecent(limit: 1);
      expect(newest.single.itemId, 'item-${LocalSchema.readHistoryLimit + 24}');
    });
  });

  test('deleteEverything her tabloyu boşaltır', () async {
    await interestsRepository.replaceAll(['Flutter']);
    await savedItemsRepository.add(
      SavedItem(
        id: 'item-1',
        kind: 'article',
        title: 'Kayıt',
        savedAt: DateTime.fromMillisecondsSinceEpoch(1),
      ),
    );
    await db.insert(FavoritesTable.name, {
      FavoritesTable.itemId: 'item-1',
      FavoritesTable.createdAt: 1,
    });
    await readHistoryRepository.record('item-1', 'article');
    await db.insert(AssistantProjectsTable.name, {
      AssistantProjectsTable.id: 'project-1',
      AssistantProjectsTable.title: 'Proje',
      AssistantProjectsTable.createdAt: 1,
      AssistantProjectsTable.updatedAt: 1,
    });
    await db.insert(AssistantConversationsTable.name, {
      AssistantConversationsTable.id: 'conversation-1',
      AssistantConversationsTable.projectId: 'project-1',
      AssistantConversationsTable.createdAt: 1,
    });
    await db.insert(AssistantMessagesTable.name, {
      AssistantMessagesTable.conversationId: 'conversation-1',
      AssistantMessagesTable.role: 'assistant',
      AssistantMessagesTable.content: 'Yanıt',
      AssistantMessagesTable.createdAt: 1,
    });
    // Feed önbelleği de silinir: içerik kişisel veri değil ama satır **ne zaman
    // senkronize edildiğini** taşır ve "tüm yerel verileri sil" diyen bir
    // kullanıcıya kullanım zamanını gösteren bir kayıt bırakılmaz.
    await db.insert(FeedCacheTable.name, {
      FeedCacheTable.id: 1,
      FeedCacheTable.payload: '{}',
      FeedCacheTable.fetchedAt: 1,
      FeedCacheTable.generatedAt: 1,
      FeedCacheTable.sourceUrl: 'https://ornek.test/feed.json',
    });

    for (final table in LocalTables.all) {
      expect(
        await _rowCount(db, table),
        greaterThan(0),
        reason: '$table test önkoşulunda dolu olmalı',
      );
    }

    await localDataRepository.deleteEverything();

    // Tek tek değil liste üzerinden: yeni bir tablo eklendiğinde bu test
    // kendiliğinden onu da kapsar. Sabit bir liste yazılsaydı, unutulan tablo
    // ancak kullanıcıda silinmeyen veri olarak görünürdü.
    for (final table in LocalTables.all) {
      expect(await _rowCount(db, table), 0, reason: '$table boşalmalı');
    }
  });
}

Future<int> _rowCount(Database db, String table) async {
  // Sqflite.firstIntValue yerine doğrudan okuma: sqflite_common_ffi üzerinden
  // Sqflite yardımcı sınıfı görünmüyor, bu biçim her varyantta çalışır.
  final rows = await db.rawQuery('SELECT COUNT(*) AS row_count FROM $table');
  return (rows.first['row_count'] as int?) ?? 0;
}
