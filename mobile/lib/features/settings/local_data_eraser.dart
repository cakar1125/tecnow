import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Ayarlar → `Verileri Sil` akışının tamamı.
///
/// Sırayla: veritabanını boşalt → onboarding bayrağını sıfırla → açık
/// ekranların durumunu hizala → adetleri yenile.
///
/// **Tohumlama bayrağı bilinçli olarak sıfırlanmaz.** Sıfırlansaydı fixture
/// kayıtları bir sonraki açılışta geri gelir ve kullanıcının "sil" kararı
/// geri alınmış olurdu. `SavedItemsSeeder` zaten bu davranış için
/// tasarlanmıştı ve `test/data/saved_persistence_test.dart` bunu doğruluyor.
/// (`NEXT_ACTION.md` bir ara "tohumlama bayrağı da temizlenmeli" diyordu;
/// bu not yanlıştı ve burada düzeltildi.)
///
/// Onboarding bayrağı ise sıfırlanır: ilgi alanları silindiği için uygulama
/// bir sonraki açılışta kurulumu yeniden sormalıdır, yoksa boş ama
/// "kurulmuş" bir durumda kalır.
Future<void> eraseAllLocalData(WidgetRef ref) async {
  final repository = await ref.read(localDataRepositoryProvider.future);
  await repository.deleteEverything();

  final preferences = await ref.read(appPreferencesProvider.future);
  await preferences.reset();

  ref.read(savedItemsProvider.notifier).reflectExternalClear();
  ref.read(interestsProvider.notifier).reflectExternalClear();
  await ref.read(localDataCountsProvider.notifier).reload();
}
