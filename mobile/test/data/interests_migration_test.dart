import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tecos/data/interests_migration.dart';
import 'package:tecos/data/local/app_database.dart';
import 'package:tecos/data/repositories/interests_repository.dart';

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

      expect(migrated, ['yapay-zeka', 'mobil', 'acik-kaynak']);
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
    expect(result, ['bulut', 'oyun']);
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

  /// Etiket → kimlik normalleştirmesi.
  ///
  /// 28 Temmuz 2026'ya kadar ilgi alanı ekranı Türkçe etiketi saklıyordu ve
  /// feed'in konuları İngilizce slug olduğu için "Sana Özel" sekmesi hiçbir
  /// zaman eşleşme bulamıyordu. Cihazda bulundu: telefonda üç ilgi alanı
  /// seçiliydi ve açılış sekmesi boştu.
  group('etiket → kimlik normalleştirmesi', () {
    test('etiket olarak saklanmış satırlar kimliğe çevrilir', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      // Cihazda bulunan gerçek durum.
      await withRepository(
        (repository) =>
            repository.replaceAll(const ['Yapay Zekâ', 'Mobil', 'Açık Kaynak']),
      );
      final result = await withRepository((repository) async {
        await InterestsMigration(repository, preferences).migrateIfNeeded();
        return repository.readAll();
      });

      expect(result, ['yapay-zeka', 'mobil', 'acik-kaynak']);
    });

    /// Bayrağı yok; idempotent olması gerekiyor.
    test('ikinci koşuda hiçbir şey değişmez', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await withRepository(
        (repository) => repository.replaceAll(const ['Yapay Zekâ']),
      );
      await withRepository(
        (repository) =>
            InterestsMigration(repository, preferences).migrateIfNeeded(),
      );
      final result = await withRepository((repository) async {
        await InterestsMigration(repository, preferences).migrateIfNeeded();
        return repository.readAll();
      });

      expect(result, ['yapay-zeka']);
    });

    test('aynı ilgi alanı hem etiket hem kimlikse tekilleşir', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await withRepository(
        (repository) => repository.replaceAll(const ['Mobil', 'mobil']),
      );
      final result = await withRepository((repository) async {
        await InterestsMigration(repository, preferences).migrateIfNeeded();
        return repository.readAll();
      });

      expect(result, ['mobil']);
    });

    test('tanınmayan değere dokunulmaz', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await withRepository(
        (repository) => repository.replaceAll(const ['bilinmeyen-alan']),
      );
      final result = await withRepository((repository) async {
        await InterestsMigration(repository, preferences).migrateIfNeeded();
        return repository.readAll();
      });

      expect(result, ['bilinmeyen-alan']);
    });
  });
}
