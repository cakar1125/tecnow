import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:teknoakis/data/local/app_database.dart';
import 'package:teknoakis/data/repositories/saved_items_repository.dart';
import 'package:teknoakis/data/saved_items_seeder.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

/// Kalıcılığın **gerçek** kanıtı: bellek içi sahte depo değil, sqflite.
///
/// Bu dosya "uygulamayı yeniden başlatma"yı, aynı veritabanı dosyasını
/// kapatıp yeniden açarak taklit eder.
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

  test('tohumlama ilk açılışta fixture kayıtlarını yazar', () async {
    final database = await openDatabase();
    final repository = SqfliteSavedItemsRepository(database);
    final preferences = await SharedPreferences.getInstance();

    await SavedItemsSeeder(repository, preferences).seedIfNeeded();
    final items = await repository.readAll();
    await database.close();

    expect(items, hasLength(savedItemFixtures.length));
    expect(
      items.map((item) => item.title),
      savedItemFixtures.map((fixture) => fixture.title),
      reason: 'savedAt DESC sıralaması fixture sırasını korumalı',
    );
  });

  test('tohumlama ikinci açılışta tekrar çalışmaz', () async {
    final preferences = await SharedPreferences.getInstance();

    final first = await openDatabase();
    await SavedItemsSeeder(
      SqfliteSavedItemsRepository(first),
      preferences,
    ).seedIfNeeded();
    await first.close();

    final second = await openDatabase();
    final repository = SqfliteSavedItemsRepository(second);
    await SavedItemsSeeder(repository, preferences).seedIfNeeded();
    final items = await repository.readAll();
    await second.close();

    expect(items, hasLength(savedItemFixtures.length));
  });

  test('kaldırılan kayıt yeniden açılışta geri gelmez', () async {
    final preferences = await SharedPreferences.getInstance();
    final removedId = savedItemFixtures.first.id;

    final first = await openDatabase();
    final firstRepository = SqfliteSavedItemsRepository(first);
    await SavedItemsSeeder(firstRepository, preferences).seedIfNeeded();
    await firstRepository.removeById(removedId);
    await first.close();

    final second = await openDatabase();
    final secondRepository = SqfliteSavedItemsRepository(second);
    // Açılış tohumlaması yeniden çalışır; silinen kaydı geri getirmemeli.
    await SavedItemsSeeder(secondRepository, preferences).seedIfNeeded();
    final items = await secondRepository.readAll();
    await second.close();

    expect(items, hasLength(savedItemFixtures.length - 1));
    expect(items.map((item) => item.id), isNot(contains(removedId)));
  });

  test('kullanıcı hepsini silince fixture kayıtları geri getirilmez', () async {
    final preferences = await SharedPreferences.getInstance();

    final first = await openDatabase();
    final firstRepository = SqfliteSavedItemsRepository(first);
    await SavedItemsSeeder(firstRepository, preferences).seedIfNeeded();
    await firstRepository.clear();
    await first.close();

    final second = await openDatabase();
    final secondRepository = SqfliteSavedItemsRepository(second);
    await SavedItemsSeeder(secondRepository, preferences).seedIfNeeded();
    final items = await secondRepository.readAll();
    await second.close();

    expect(
      items,
      isEmpty,
      reason: 'boş liste kullanıcı kararıdır, tohumlama bayrağı bunu korumalı',
    );
  });
}
