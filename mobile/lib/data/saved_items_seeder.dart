import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/fixtures.dart';
import 'repositories/saved_items_repository.dart';

/// Kaydedilenler tablosunu ilk açılışta fixture kayıtlarıyla doldurur.
///
/// Tohumlama **okuma yolundan ayrıdır** ve uygulama açılışında bir kez
/// çalıştırılır (`lib/app/bootstrap.dart`). Yazma işlemini bir okuma
/// provider'ının içine koymak, ekranın her yenilenişinde
/// okuma → yazma → invalidate döngüsü üretiyordu; TASK-0009 bu yüzden geri
/// alındı (`orchestration/results/TASK-0009_RESULT.md`).
final class SavedItemsSeeder {
  SavedItemsSeeder(this._repository, this._preferences);

  static const seedFlagKey = 'saved_items_seeded_v1';

  final SavedItemsRepository _repository;
  final SharedPreferences _preferences;

  /// Bayrak, kullanıcı tüm kayıtları sildikten sonra fixture'ların geri
  /// gelmesini engeller: boş liste bilinçli bir kullanıcı kararı olabilir.
  Future<void> seedIfNeeded() async {
    if (_preferences.getBool(seedFlagKey) ?? false) return;

    final existing = await _repository.readAll();
    if (existing.isEmpty) {
      final seededAt = DateTime.now();
      for (var index = 0; index < savedItemFixtures.length; index++) {
        final fixture = savedItemFixtures[index];
        await _repository.add(
          SavedItem(
            id: fixture.id,
            kind: fixture.kind.name,
            title: fixture.title,
            sourceLabel: fixture.sourceLabel,
            summary: fixture.summary,
            // Depo `savedAt DESC` sıralar; azalan damga fixture sırasını korur.
            savedAt: seededAt.subtract(Duration(milliseconds: index)),
          ),
        );
      }
    }

    await _preferences.setBool(seedFlagKey, true);
  }
}
