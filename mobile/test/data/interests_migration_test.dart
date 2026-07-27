import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:teknoakis/data/interests_migration.dart';
import 'package:teknoakis/data/local/app_database.dart';
import 'package:teknoakis/data/repositories/interests_repository.dart';

/// Faz 1'de ilgi alanları `shared_preferences`'ta bir string listesiydi.
/// Bu testler, mevcut kullanıcıların seçimlerinin taşımada kaybolmadığını
/// ve taşımanın tekrar tekrar çalışmadığını gerçek sqflite ile ölçer.
void main() {
  setUpAll(sqfliteFfiInit);

  late String databasePath;

  setUp(() async {
    final directory = await databaseFactoryFfi.getDatabasesPath();
    databasePath =
        '$directory/interests_migration_${DateTime.now().microsecondsSinceEpoch}.db';
    await databaseFactoryFfi.deleteDatabase(databasePath);
  });

  tearDown(() => databaseFactoryFfi.deleteDatabase(databasePath));

  Future<T> withRepository<T>(
    Future<T> Function(InterestsRepository repository) run,
  ) async {
    final database = await AppDatabase.open(
      path: databasePath,
      factory: databaseFactoryFfi,
    );
    try {
      return await run(SqfliteInterestsRepository(database));
    } finally {
      await database.close();
    }
  }

  test(
    'eski anahtardaki seçimler tabloya taşınır ve anahtar silinir',
    () async {
      SharedPreferences.setMockInitialValues({
        InterestsMigration.legacyKey: ['Yapay Zekâ', 'Mobil', 'Açık Kaynak'],
      });
      final preferences = await SharedPreferences.getInstance();

      final migrated = await withRepository((repository) async {
        await InterestsMigration(repository, preferences).migrateIfNeeded();
        return repository.readAll();
      });

      expect(migrated, ['Yapay Zekâ', 'Mobil', 'Açık Kaynak']);
      expect(preferences.getStringList(InterestsMigration.legacyKey), isNull);
    },
  );

  test('taşıma ikinci açılışta tekrar çalışmaz', () async {
    SharedPreferences.setMockInitialValues({
      InterestsMigration.legacyKey: ['Mobil'],
    });
    final preferences = await SharedPreferences.getInstance();

    await withRepository(
      (repository) =>
          InterestsMigration(repository, preferences).migrateIfNeeded(),
    );
    // Kullanıcı taşımadan sonra seçimini değiştirdi.
    await withRepository(
      (repository) => repository.replaceAll(const ['Bulut', 'Oyun']),
    );
    await withRepository(
      (repository) =>
          InterestsMigration(repository, preferences).migrateIfNeeded(),
    );

    final result = await withRepository((repository) => repository.readAll());
    expect(result, ['Bulut', 'Oyun']);
  });

  test('tablo doluysa eski anahtar üzerine yazmaz', () async {
    SharedPreferences.setMockInitialValues({
      InterestsMigration.legacyKey: ['Bayat'],
    });
    final preferences = await SharedPreferences.getInstance();

    await withRepository(
      (repository) => repository.replaceAll(const ['Güncel']),
    );
    final result = await withRepository((repository) async {
      await InterestsMigration(repository, preferences).migrateIfNeeded();
      return repository.readAll();
    });

    expect(result, ['Güncel']);
    expect(preferences.getStringList(InterestsMigration.legacyKey), isNull);
  });

  test('eski anahtar yoksa hiçbir şey yapmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final result = await withRepository((repository) async {
      await InterestsMigration(repository, preferences).migrateIfNeeded();
      return repository.readAll();
    });

    expect(result, isEmpty);
  });
}
