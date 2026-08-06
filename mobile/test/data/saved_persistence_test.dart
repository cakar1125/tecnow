import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tecnow/data/local/app_database.dart';
import 'package:tecnow/data/repositories/saved_items_repository.dart';
import 'package:tecnow/data/saved_items_sample_cleanup.dart';
import 'package:tecnow/fixtures/fixtures.dart';

/// Kalıcılığın **gerçek** kanıtı: bellek içi sahte depo değil, sqflite.
///
/// Bu dosya "uygulamayı yeniden başlatma"yı, aynı veritabanı dosyasını
/// kapatıp yeniden açarak taklit eder.
///
/// Önceki hâli açılış **tohumlamasını** ölçüyordu. Tohumlama 2026-07-28'de
/// kaldırıldı (uygulama artık kullanıcının hiç kaydetmediği üç kaydı hazır
/// bulundurmuyor), yerine iki şey geldi ve ikisi de burada ölçülüyor:
/// gerçek kaydetmenin kalıcılığı ve eski cihazlardaki örnek satırların bir
/// kereye mahsus temizliği.
void main() {
  setUpAll(sqfliteFfiInit);

  late String databasePath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Dosya tabanlı geçici veritabanı: `inMemoryDatabasePath` kapatıldığında
    // içeriği kaybolur ve yeniden açma testi anlamsızlaşır.
    final directory = await databaseFactoryFfi.getDatabasesPath();
    databasePath =
        '$directory/saved_persistence_${DateTime.now().microsecondsSinceEpoch}.db';
    await databaseFactoryFfi.deleteDatabase(databasePath);
  });

  tearDown(() => databaseFactoryFfi.deleteDatabase(databasePath));

  Future<Database> openDatabase() =>
      AppDatabase.open(path: databasePath, factory: databaseFactoryFfi);

  SavedItem realItem(String id) => SavedItem(
    id: id,
    kind: 'announcement',
    title: 'Gerçek bir duyuru',
    sourceLabel: 'OpenAI Blog',
    summary: 'Kullanıcının kendi kaydettiği içerik.',
    savedAt: DateTime(2026, 7, 28, 9),
  );

  group('kaydetmenin kalıcılığı', () {
    test('kaydedilen içerik uygulama yeniden açılınca durur', () async {
      final first = await openDatabase();
      await SqfliteSavedItemsRepository(
        first,
      ).add(realItem('a1b2c3d4e5f60718'));
      await first.close();

      final second = await openDatabase();
      final items = await SqfliteSavedItemsRepository(second).readAll();
      await second.close();

      expect(items.map((item) => item.id), ['a1b2c3d4e5f60718']);
      expect(items.single.title, 'Gerçek bir duyuru');
      // Tür serbest metin olarak saklanır; kartın rozeti buradan okunuyor.
      expect(items.single.kind, 'announcement');
    });

    test('kaldırılan kayıt yeniden açılışta geri gelmez', () async {
      final first = await openDatabase();
      final repository = SqfliteSavedItemsRepository(first);
      await repository.add(realItem('a1b2c3d4e5f60718'));
      await repository.removeById('a1b2c3d4e5f60718');
      await first.close();

      final second = await openDatabase();
      final items = await SqfliteSavedItemsRepository(second).readAll();
      await second.close();

      expect(items, isEmpty);
    });
  });

  group('örnek kayıt temizliği', () {
    /// Tohumlanmış bir cihazı taklit eder: eski sürüm fixture satırlarını
    /// yazmış ve bayrağını bırakmıştır.
    Future<void> seedLikeOldVersion(SavedItemsRepository repository) async {
      for (var index = 0; index < savedItemFixtures.length; index++) {
        final fixture = savedItemFixtures[index];
        await repository.add(
          SavedItem(
            id: fixture.id,
            kind: fixture.kind.name,
            title: fixture.title,
            sourceLabel: fixture.sourceLabel,
            summary: fixture.summary,
            savedAt: DateTime(2026, 7, 27).subtract(Duration(seconds: index)),
          ),
        );
      }
      SharedPreferences.setMockInitialValues({
        SavedItemsSampleCleanup.legacySeedFlagKey: true,
      });
    }

    test('tohumlanmış örnek satırları siler', () async {
      final database = await openDatabase();
      final repository = SqfliteSavedItemsRepository(database);
      await seedLikeOldVersion(repository);

      await SavedItemsSampleCleanup(
        repository,
        await SharedPreferences.getInstance(),
      ).removeIfNeeded();
      final items = await repository.readAll();
      await database.close();

      expect(items, isEmpty);
    });

    /// Asıl risk bu: temizlik kullanıcının **kendi** kaydettiğine dokunamaz.
    test('kullanıcının kendi kayıtlarına dokunmaz', () async {
      final database = await openDatabase();
      final repository = SqfliteSavedItemsRepository(database);
      await seedLikeOldVersion(repository);
      await repository.add(realItem('a1b2c3d4e5f60718'));

      await SavedItemsSampleCleanup(
        repository,
        await SharedPreferences.getInstance(),
      ).removeIfNeeded();
      final items = await repository.readAll();
      await database.close();

      expect(items.map((item) => item.id), ['a1b2c3d4e5f60718']);
    });

    /// Temizlik tek seferliktir. Aksi hâlde, kullanıcı ileride aynı kimlikle
    /// bir şey kaydederse her açılışta sessizce silinirdi.
    test('bir kez çalıştıktan sonra tekrar silmez', () async {
      final database = await openDatabase();
      final repository = SqfliteSavedItemsRepository(database);
      await seedLikeOldVersion(repository);
      final preferences = await SharedPreferences.getInstance();

      await SavedItemsSampleCleanup(repository, preferences).removeIfNeeded();
      // Temizlikten sonra aynı kimlik yeniden yazılırsa korunmalı.
      final resurrected = savedItemFixtures.first.id;
      await repository.add(realItem(resurrected));
      await SavedItemsSampleCleanup(repository, preferences).removeIfNeeded();
      final items = await repository.readAll();
      await database.close();

      expect(items.map((item) => item.id), [resurrected]);
    });

    test('temizlenmiş cihazda eski tohumlama bayrağı kalmaz', () async {
      final database = await openDatabase();
      final repository = SqfliteSavedItemsRepository(database);
      await seedLikeOldVersion(repository);
      final preferences = await SharedPreferences.getInstance();

      await SavedItemsSampleCleanup(repository, preferences).removeIfNeeded();
      await database.close();

      expect(
        preferences.getBool(SavedItemsSampleCleanup.legacySeedFlagKey),
        isNull,
      );
      expect(
        preferences.getBool(SavedItemsSampleCleanup.cleanupFlagKey),
        isTrue,
      );
    });
  });
}
