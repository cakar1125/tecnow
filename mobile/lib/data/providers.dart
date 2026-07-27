import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app_preferences.dart';
import 'feed/feed_repository.dart';
import 'feed/feed_schema.dart';
import 'interests_migration.dart';
import 'local/app_database.dart';
import 'repositories/interests_repository.dart';
import 'repositories/local_data_repository.dart';
import 'repositories/read_history_repository.dart';
import 'repositories/saved_items_repository.dart';
import 'saved_items_seeder.dart';

final databaseProvider = FutureProvider<Database>((ref) => AppDatabase.open());

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => BundledFeedRepository(),
);

/// Paketlenmiş feed. Geri çekilmiş kayıtlar **gösterilmez** ama dosyadan
/// silinmez: politika düzeltmeyi kayıtla yönetmeyi şart koşuyor.
final feedProvider = AsyncNotifierProvider<FeedNotifier, List<FeedItem>>(
  FeedNotifier.new,
);

final class FeedNotifier extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() async {
    final feed = await ref.watch(feedRepositoryProvider).load();
    return feed.visibleItems;
  }

  /// Ağ tazelemesi geldiğinde (TASK-0016) buradan tetiklenecek.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

/// Tek bir kayıt. Detay ekranları kimlikle çağırır; bulunamazsa `null`.
///
/// Kimlik kanonik adresten türetildiği için kalıcıdır: kaydedilen bir içerik,
/// feed yeniden üretildiğinde de aynı kimlikle bulunur.
final feedItemProvider = Provider.family<FeedItem?, String>((ref, id) {
  final items = ref.watch(feedProvider).value;
  if (items == null) return null;
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
});

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

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return AppPreferences(preferences);
});

final savedItemsSeederProvider = FutureProvider<SavedItemsSeeder>((ref) async {
  final repository = await ref.watch(savedItemsRepositoryProvider.future);
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return SavedItemsSeeder(repository, preferences);
});

final interestsMigrationProvider = FutureProvider<InterestsMigration>((
  ref,
) async {
  final repository = await ref.watch(interestsRepositoryProvider.future);
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return InterestsMigration(repository, preferences);
});

/// Seçili ilgi alanları.
///
/// TASK-0009-R deseni: `build` yalnız okur, mutasyonlar durumu doğrudan
/// günceller, `invalidate` yoktur. [persist] açıkça çağrılır — çip'e her
/// dokunuşta veritabanına yazmak, kullanıcı henüz seçimini bitirmeden
/// kalıcı hale getirirdi.
final interestsProvider = AsyncNotifierProvider<InterestsNotifier, Set<String>>(
  InterestsNotifier.new,
);

final class InterestsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final repository = await ref.watch(interestsRepositoryProvider.future);
    return (await repository.readAll()).toSet();
  }

  void toggle(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.contains(value)
          ? ({...current}..remove(value))
          : {...current, value},
    );
  }

  Future<void> persist() async {
    final current = state.value;
    if (current == null) return;
    final repository = await ref.read(interestsRepositoryProvider.future);
    await repository.replaceAll(current.toList(growable: false));
  }

  /// Bkz. [SavedItemsNotifier.reflectExternalClear].
  void reflectExternalClear() => state = const AsyncData(<String>{});
}

/// Ayarlar'daki yerel kayıt adetleri.
///
/// Salt okuma; [LocalDataCountsNotifier.reload] silme sonrası açıkça çağrılır.
final localDataCountsProvider =
    AsyncNotifierProvider<LocalDataCountsNotifier, LocalDataCounts>(
      LocalDataCountsNotifier.new,
    );

final class LocalDataCountsNotifier extends AsyncNotifier<LocalDataCounts> {
  @override
  Future<LocalDataCounts> build() async {
    final repository = await ref.watch(localDataRepositoryProvider.future);
    return repository.readCounts();
  }

  Future<void> reload() async {
    final repository = await ref.read(localDataRepositoryProvider.future);
    state = AsyncData(await repository.readCounts());
  }
}

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

  /// Veritabanı başka bir yerden boşaltıldığında ekran durumunu hizalar
  /// (Ayarlar → `Verileri Sil`). Kendisi **yazmaz**.
  void reflectExternalClear() => state = const AsyncData([]);

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
