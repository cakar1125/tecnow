import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/interests_repository.dart';

/// İlgi alanlarını `shared_preferences`'tan sqflite'a taşır.
///
/// Faz 1'de seçimler `selected_interests` anahtarında bir string listesi
/// olarak tutuluyordu. `LOCAL_DATA_ARCHITECTURE.md` listeleri sqflite'a
/// yazdığı için tablo asıl kaynak oldu; bu geçiş, mevcut kullanıcıların
/// seçimlerini kaybetmemesi için vardır.
///
/// Açılışta bir kez çalışır ([SavedItemsSeeder] ile aynı yerde) ve
/// tamamlandığında eski anahtarı siler — bayrak eski anahtarın kendisidir.
final class InterestsMigration {
  const InterestsMigration(this._repository, this._preferences);

  static const legacyKey = 'selected_interests';

  final InterestsRepository _repository;
  final SharedPreferences _preferences;

  Future<void> migrateIfNeeded() async {
    final legacy = _preferences.getStringList(legacyKey);
    if (legacy == null) return;

    if (legacy.isNotEmpty) {
      // Tablo doluysa sqflite kazanır: kullanıcı taşımadan sonra seçim
      // değiştirmiş olabilir ve eski anahtar bayat kalmış olabilir.
      final existing = await _repository.readAll();
      if (existing.isEmpty) {
        await _repository.replaceAll(legacy);
      }
    }

    await _preferences.remove(legacyKey);
  }
}
