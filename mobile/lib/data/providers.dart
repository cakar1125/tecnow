import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'local/app_database.dart';
import 'repositories/interests_repository.dart';
import 'repositories/local_data_repository.dart';
import 'repositories/read_history_repository.dart';
import 'repositories/saved_items_repository.dart';
import 'saved_items_seeder.dart';

final databaseProvider = FutureProvider<Database>((ref) => AppDatabase.open());

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final interestsRepositoryProvider = FutureProvider<InterestsRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteInterestsRepository(database);
});

final savedItemsRepositoryProvider = FutureProvider<SavedItemsRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteSavedItemsRepository(database);
});

final readHistoryRepositoryProvider = FutureProvider<ReadHistoryRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteReadHistoryRepository(database);
});

final localDataRepositoryProvider = FutureProvider<LocalDataRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteLocalDataRepository(database);
});

final savedItemsSeederProvider = FutureProvider<SavedItemsSeeder>((ref) async {
  final repository = await ref.watch(savedItemsRepositoryProvider.future);
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return SavedItemsSeeder(repository, preferences);
});

/// Kaydedilenler listesi.
///
/// `build` **yalnız okur**. Tohumlama açılışta ayrıca çalışır
/// ([SavedItemsSeeder]); mutasyonlar `invalidate` yerine durumu doğrudan
/// günceller. İkisi de bilinçli: TASK-0009'da okuma provider'ı aynı zamanda
/// tohumluyor ve ekran silme sonrası `invalidate` çağırıyordu, bu da
/// yerleşmeyen bir okuma/yazma döngüsü üretiyordu.
final savedItemsProvider =
    AsyncNotifierProvider<SavedItemsNotifier, List<SavedItem>>(
      SavedItemsNotifier.new,
    );

final class SavedItemsNotifier extends AsyncNotifier<List<SavedItem>> {
  @override
  Future<List<SavedItem>> build() async {
    final repository = await ref.watch(savedItemsRepositoryProvider.future);
    return repository.readAll();
  }

  Future<void> remove(String id) async {
    // Riverpod 3'te `AsyncValue.value` zaten nullable; `valueOrNull` yok.
    final previous = state.value;
    if (previous == null) return;

    // İyimser güncelleme: liste önce güncellenir, yazma başarısız olursa
    // eski liste geri konur. Böylece hiçbir yeniden okuma tetiklenmez.
    state = AsyncData(
      previous.where((item) => item.id != id).toList(growable: false),
    );
    try {
      final repository = await ref.read(savedItemsRepositoryProvider.future);
      await repository.removeById(id);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
