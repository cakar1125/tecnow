import 'package:shared_preferences/shared_preferences.dart';

import 'interests/interest_taxonomy.dart';
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
    if (legacy != null) {
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

    await _normalizeIds();
  }

  /// Etiket olarak saklanmış satırları kalıcı kimliğe çevirir.
  ///
  /// 28 Temmuz 2026'ya kadar ilgi alanı ekranı Türkçe **etiketi** yazıyordu
  /// (`Yapay Zekâ`). Feed'in konuları İngilizce slug olduğu için "Sana Özel"
  /// sekmesi hiçbir zaman eşleşme bulamıyordu; cihazda bulundu.
  ///
  /// Bayrağı yok çünkü **kendinden idempotent**: kimlikler etiket
  /// tablosunda karşılık bulmaz, dolayısıyla ikinci koşuda hiçbir şey
  /// değişmez. Değişiklik yoksa yazma da yapılmaz.
  Future<void> _normalizeIds() async {
    final stored = await _repository.readAll();
    if (stored.isEmpty) return;

    final byLabel = {
      for (final interest in interestTaxonomy) interest.label: interest.id,
    };

    final normalized = <String>[];
    var changed = false;
    for (final value in stored) {
      final mapped = byLabel[value];
      if (mapped != null && mapped != value) changed = true;
      final resolved = mapped ?? value;
      // Aynı ilgi alanı hem etiket hem kimlik olarak duruyorsa tekilleşir.
      if (!normalized.contains(resolved)) normalized.add(resolved);
    }

    if (!changed && normalized.length == stored.length) return;
    await _repository.replaceAll(normalized);
  }
}
