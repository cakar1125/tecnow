import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/fixtures.dart';
import 'repositories/saved_items_repository.dart';

/// Tohumlanmış örnek kayıtları bir kez temizler.
///
/// 2026-07-28'e kadar uygulama ilk açılışta Kaydedilenler tablosunu fixture
/// kayıtlarıyla dolduruyordu (`SavedItemsSeeder`). Üç sebeple kaldırıldı:
///
/// 1. Gerçek bir kullanıcı, hiç kaydetmediği üç kaydı hazır buluyordu.
/// 2. Kaydetme düğmesi hiçbir şey yazmıyordu (yalnız kendi rengini
///    çeviriyordu), yani bu üç kayıt sekmenin **tek** olası içeriğiydi;
///    silindiklerinde sekme kalıcı olarak boşalıyordu.
/// 3. Detay ekranı kimliğe göre çözülmeye başlayınca örnek kimlikler akışta
///    bulunamaz oldu: örnek kayda dokunmak "İçerik bulunamadı" veriyordu.
///
/// Tohumlama kaldırıldı, ama **tohumlanmış cihazlar var** (geliştirme
/// telefonu, cihaz kabulü). Yeni kurulumda bu sınıfın yapacağı bir şey yok;
/// eski kurulumda o üç satırı siler.
///
/// Yalnız fixture kimlikleri silinir. Gerçek feed kimlikleri 16 haneli
/// onaltılık; çakışma mümkün değil ve kullanıcının kendi kaydettiğine
/// dokunulmaz.
final class SavedItemsSampleCleanup {
  SavedItemsSampleCleanup(this._repository, this._preferences);

  /// Tohumlama bayrağı — artık yazılmıyor, yalnız temizleniyor.
  static const legacySeedFlagKey = 'saved_items_seeded_v1';

  static const cleanupFlagKey = 'saved_items_samples_removed_v1';

  final SavedItemsRepository _repository;
  final SharedPreferences _preferences;

  Future<void> removeIfNeeded() async {
    if (_preferences.getBool(cleanupFlagKey) ?? false) return;

    for (final fixture in savedItemFixtures) {
      await _repository.removeById(fixture.id);
    }

    await _preferences.remove(legacySeedFlagKey);
    await _preferences.setBool(cleanupFlagKey, true);
  }
}
