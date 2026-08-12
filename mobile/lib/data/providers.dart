import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_preferences.dart';
import 'feed/feed_cache.dart';
import 'feed/feed_endpoint.dart';
import 'feed/feed_http_client.dart';
import 'feed/feed_repository.dart';
import 'feed/feed_schema.dart';
import 'feed/feed_sync_state.dart';
import 'feed/syncing_feed_repository.dart';
import 'interests/interest_taxonomy.dart';
import 'interests_migration.dart';
import 'local/app_database.dart';
import 'local/schema.dart';
import 'repositories/interests_repository.dart';
import 'repositories/local_data_repository.dart';
import 'repositories/read_history_repository.dart';
import 'repositories/saved_items_repository.dart';
import 'saved_items_sample_cleanup.dart';

final databaseProvider = FutureProvider<Database>((ref) => AppDatabase.open());

/// Uzak feed adresleri, sırayla: birincil ve (varsa) yedek.
///
/// `--dart-define=FEED_URL=...` verilmediyse liste **boştur** ve uygulama
/// yalnız paketlenmiş içerikle çalışır.
final feedEndpointsProvider = Provider<List<Uri>>(
  (ref) => parseFeedEndpoints(
    feedUrlFromEnvironment,
    feedFallbackUrlFromEnvironment,
  ),
);

final feedHttpClientProvider = Provider<FeedHttpClient>(
  (ref) => IoFeedHttpClient(),
);

/// Veritabanını `Future` olarak geçirir; böylece bu sağlayıcı eşzamanlı kalır
/// ve feed'i okuyan hiçbir ekran veritabanı açılışını beklemez.
final feedCacheProvider = Provider<FeedCache>(
  (ref) => SqfliteFeedCache(ref.watch(databaseProvider.future)),
);

/// Cihazın dili — içerik dili tercihi yokken kullanılan varsayılan.
///
/// Ayrı bir sağlayıcı olması testler için: gerçek `PlatformDispatcher`'ı
/// okuyan bir kod yolu, ölçümü çalıştığı makinenin diline bağlar.
///
/// **`locale` değil `locales` okunuyor.** `PlatformDispatcher.locale`,
/// `locales.first` demek ve liste boşsa **fırlatır**. Boş liste gerçek bir
/// durum: gömülü ortamlarda ve bazı test koşucularında dil hiç bildirilmiyor.
/// Bu sağlayıcı `feedRepositoryProvider`'ın kurulum yolunda olduğu için orada
/// atılan bir istisna feed'i değil **uygulamanın tamamını** düşürürdü — ve
/// sebebi "cihaz dilini soramadım" olurdu, ki bu tercih bir kolaylık, koşul
/// değil. Bilinmiyorsa `null`: yayının kendi dili kullanılır.
final deviceLanguageProvider = Provider<String?>((ref) {
  final locales = PlatformDispatcher.instance.locales;
  if (locales.isEmpty) return null;
  return locales.first.languageCode;
});

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => SyncingFeedRepository(
    bundled: BundledFeedRepository(),
    cache: ref.watch(feedCacheProvider),
    client: ref.watch(feedHttpClientProvider),
    endpoints: ref.watch(feedEndpointsProvider),
    // `watch`: dil değiştiğinde depo yeniden kurulur ve bir sonraki tazeleme
    // doğru dosyaya gider. `read` olsaydı seçim ancak uygulama yeniden
    // başlatılınca işlerdi.
    preferredLanguage: ref.watch(feedLanguageProvider),
    deviceLanguage: ref.watch(deviceLanguageProvider),
  ),
);

/// Gösterilen içerik. Geri çekilmiş kayıtlar **gösterilmez** ama dosyadan
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

  /// Yerel kaynağı baştan okur. Ağa çıkmaz.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Uzak adresten tazelemeyi dener.
  ///
  /// **`AsyncLoading` yazılmaz.** Tazeleme sırasında ekranı boşaltmak,
  /// çalışan bir listeyi ağ hatası ihtimali uğruna feda etmek olurdu:
  /// kullanıcı eski içeriği görmeye devam eder, sonuç gelince liste yerinde
  /// değişir. Başarısızlıkta durum hiç değişmez.
  Future<FeedSyncOutcome> refresh() async {
    final outcome = await ref.read(feedRepositoryProvider).refresh();
    if (outcome.feed case final feed?) {
      state = AsyncData(feed.visibleItems);
    }
    return outcome;
  }
}

/// İçerik güncelliği. Arayüzün "son güncelleme" satırı ve tazeleme kontrolü
/// buna bakar.
final feedSyncProvider = AsyncNotifierProvider<FeedSyncNotifier, FeedSyncState>(
  FeedSyncNotifier.new,
);

final class FeedSyncNotifier extends AsyncNotifier<FeedSyncState> {
  @override
  Future<FeedSyncState> build() async {
    final repository = ref.watch(feedRepositoryProvider);
    return FeedSyncState(
      remoteEnabled: repository.remoteEnabled,
      lastSyncAt: await repository.lastSyncAt(),
    );
  }

  /// Açılışta yalnız **bayatsa** dener.
  ///
  /// Her açılışta ağa çıkmak, günde onlarca kez uygulamayı açan bir
  /// kullanıcının verisini ve pilini içerik değişmeden harcardı.
  Future<void> refreshIfStale() async {
    // Önce durumun kurulmasını bekler. Ekran bunu ilk kareden sonra çağırıyor
    // ve o an sağlayıcı hâlâ `AsyncLoading` olabilir; `state.value`a bakmak
    // açılış denemesini sessizce hiç yapmamak demekti.
    final current = await future;
    if (current.refreshing) return;
    if (!await ref.read(feedRepositoryProvider).isStale()) return;
    await refresh();
  }

  Future<FeedSyncOutcome> refresh() async {
    final current = state.value;
    // Aynı anda iki tazeleme olmaz: kullanıcı aşağı çekerken açılış denemesi
    // de tetiklenebilir ve aynı dosya iki kez indirilirdi.
    if (current == null || current.refreshing) return FeedSyncOutcome.disabled;

    state = AsyncData(current.copyWith(refreshing: true, clearFailure: true));
    final outcome = await ref.read(feedProvider.notifier).refresh();

    state = AsyncData(
      FeedSyncState(
        remoteEnabled: current.remoteEnabled,
        lastSyncAt: outcome.syncedAt ?? current.lastSyncAt,
        failure: outcome.status == FeedSyncStatus.failed
            ? outcome.failure
            : null,
      ),
    );
    return outcome;
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

/// Orijinal kaynağı işletim sistemine devreder. `true` döndürürse açıldı.
typedef UrlOpener = Future<bool> Function(Uri url);

/// Testler gerçek tarayıcı açmadan düğmenin bağlı olduğunu ölçebilsin diye
/// sağlayıcı olarak duruyor.
final urlOpenerProvider = Provider<UrlOpener>((ref) => openExternalUrl);

/// Yalnız `https` açılır.
///
/// Feed üreticisi zaten https dışını almıyor ama burası uygulamanın adresi
/// **dışarıya** verdiği yer: `intent://`, `file://` ya da `javascript:` taşıyan
/// bozuk bir kayıt buradan geçmemeli. Sınır, kaynağa güvenilen yerde değil
/// devrin yapıldığı yerde kontrol edilir.
Future<bool> openExternalUrl(Uri url) async {
  if (url.scheme != 'https') return false;
  return launchUrl(url, mode: LaunchMode.externalApplication);
}

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

/// Seçili tema.
///
/// `AsyncNotifier` değil, düz `Notifier`: `MaterialApp` bir `themeMode`
/// **beklemez**, ister. Yükleniyor durumu burada bir ekran değil, yanlış
/// temada geçen birkaç kare demektir — kullanıcının koyu seçtiği bir
/// uygulamanın açılışta beyaz parlaması. O yüzden değer `bootstrap` içinde,
/// `runApp`'ten **önce** [ThemeModeNotifier.restore] ile yerine konur ve
/// uygulama doğru temayla açılır.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Diskteki tercihi yerine koyar. Yazma yapmaz.
  void restore(ThemeMode mode) => state = mode;

  /// Kullanıcının seçimi: önce ekran değişir, sonra diske yazılır.
  ///
  /// Sıra bilinçli — yazma başarısız olsa bile tema o oturumda çalışır ve
  /// hata kullanıcının seçimini geri almaz.
  Future<void> select(ThemeMode mode) async {
    state = mode;
    final preferences = await ref.read(appPreferencesProvider.future);
    await preferences.setThemeMode(mode);
  }
}

/// Yayının sunduğu diller ve elde tutulan kopyanın dili.
///
/// Ayarlar ekranı bunu okuyup seçicisini ona göre kuruyor. Liste **yayından**
/// geliyor, uygulamadan değil: yeni bir dil eklendiğinde kurulu uygulama onu
/// bir sonraki tazelemede görüyor ve mağaza güncellemesi gerekmiyor.
final feedLanguageOptionsProvider = FutureProvider<FeedLanguageOptions>((
  ref,
) async {
  final feed = await ref.watch(feedRepositoryProvider).load();
  return FeedLanguageOptions(
    current: feed.language,
    available: feed.availableLanguages,
  );
});

final class FeedLanguageOptions {
  const FeedLanguageOptions({required this.current, required this.available});

  /// Elde tutulan feed dosyasının dili.
  final String current;

  /// Yayının sunduğu diller. Bir taneden azsa seçilecek bir şey yok.
  final List<FeedLanguage> available;

  bool get hasChoice => available.length > 1;
}

/// Seçili içerik dili. `null` = cihazın diline uy.
///
/// [ThemeModeNotifier] ile aynı desen ve aynı sebep: değer `bootstrap`
/// içinde `runApp`'ten **önce** yerine konur. Burada gecikmenin bedeli yanlış
/// tema değil, **yanlış dilde bir ağ isteği** olurdu — açılışta Türkçe dosya
/// indirilir, sonra tercih okunur ve İngilizcesi bir kez daha indirilirdi.
final feedLanguageProvider = NotifierProvider<FeedLanguageNotifier, String?>(
  FeedLanguageNotifier.new,
);

final class FeedLanguageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Diskteki tercihi yerine koyar. Yazma yapmaz.
  void restore(String? code) => state = code;

  /// Kullanıcının seçimi: önce durum değişir, sonra diske yazılır.
  ///
  /// Durum değişince [feedRepositoryProvider] yeniden kurulur; içeriğin
  /// gerçekten değişmesi için bir tazeleme gerekir, çünkü elde yalnız eski
  /// dilin kopyası vardır. Çağıran tarafın tazelemeyi tetiklemesi bilinçli:
  /// ayarlar ekranı ağ isteğini kendi başlatmaz, kullanıcı akışa döndüğünde
  /// olağan tazeleme yolu işler.
  Future<void> select(String? code) async {
    state = code;
    final preferences = await ref.read(appPreferencesProvider.future);
    await preferences.setFeedLanguage(code);
  }
}

/// Akıştan çıkarılmış kaynaklar.
///
/// Keşfet'te açılıp kapanır, **Ana Sayfa'yı** değiştirir. Bu, iki ekranı
/// birbirine bağlayan tek mekanik: Keşfet artık bir arama sonucu ekranı
/// değil, akışın kurulduğu yer.
///
/// [ThemeModeNotifier] ile aynı desende düz bir `Notifier`: değer
/// `bootstrap` içinde `runApp`'ten önce yerine konur, böylece uygulama
/// susturulmuş kaynakları bir kare bile göstermez.
final mutedSourcesProvider =
    NotifierProvider<MutedSourcesNotifier, Set<String>>(
      MutedSourcesNotifier.new,
    );

/// Susturulmuş kaynakların başlangıç değeri.
///
/// Uygulamada boş: gerçek değer diskten okunup `bootstrap` içinde
/// [MutedSourcesNotifier.restore] ile konuyor. Ayrı bir provider olmasının
/// sebebi **test**: [MutedSourcesNotifier] `final` ve alt sınıflanamıyor,
/// testler de "şu kaynak kapalıyken ekran ne yapıyor" diye sormak zorunda.
/// Sınıf kısıtını gevşetmek yerine tohum dışarı alındı.
final initialMutedSourcesProvider = Provider<Set<String>>((ref) => const {});

final class MutedSourcesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(initialMutedSourcesProvider);

  void restore(Set<String> sources) => state = sources;

  /// Kaynağı akıştan çıkarır ya da geri alır.
  ///
  /// Önce ekran, sonra disk — yazma başarısız olsa bile seçim o oturumda
  /// çalışır ve kullanıcının dokunuşu boşa gitmez.
  Future<void> toggle(String sourceName) async {
    final next = {...state};
    if (!next.remove(sourceName)) next.add(sourceName);
    state = next;
    final preferences = await ref.read(appPreferencesProvider.future);
    await preferences.setMutedSources(next);
  }
}

/// Susturulmuş kaynakları eler.
///
/// **`AsyncValue` sarmalayan bir provider değil, düz bir liste işlevi.**
/// Bir ara provider yazıp `feed.whenData(...)` demek doğal duruyordu ve
/// denendi — testler tuttu: bozuk feed'in hata durumu kayboldu, ekran
/// sonsuza dek yükleme iskeleti gösterdi. Sebebi bu depoda daha önce iki
/// kez yazılmış olan tuzak: Riverpod 3 hatayı `AsyncLoading(error: …)`
/// içinde taşıyabiliyor ve `whenData` yeniden kurarken onu düşürüyor.
///
/// Süzme bu yüzden `AsyncValue` çözüldükten **sonra**, kullanıldığı yerde
/// yapılıyor. Ham [feedProvider] olduğu gibi duruyor: Keşfet'in kaynak
/// listesi **bütün** kaynakları göstermek zorunda, yoksa kapattığın kaynağı
/// geri açamazsın.
List<FeedItem> withoutMutedSources(List<FeedItem> items, Set<String> muted) =>
    muted.isEmpty
    ? items
    : items
          .where((item) => !muted.contains(item.sourceName))
          .toList(growable: false);

final savedItemsSampleCleanupProvider = FutureProvider<SavedItemsSampleCleanup>(
  (ref) async {
    final repository = await ref.watch(savedItemsRepositoryProvider.future);
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    return SavedItemsSampleCleanup(repository, preferences);
  },
);

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
///
/// ## Sıra **yük taşıyor**
///
/// Kümenin dolaşım sırası Ana Sayfa'daki sekme sırasıdır. `Set` tipi bunu
/// vaat etmez ama Dart'ın küme değişmezleri ve `toSet()` `LinkedHashSet`
/// üretir; o da **ekleme sırasını** korur. Zincirin tamamı bu yüzden çalışıyor:
/// depo `createdAt + index` yazıp aynı sırayla okuyor
/// (`SqfliteInterestsRepository`), [toggle] sona ekliyor, [reorder] listeyi
/// yeniden kuruyor.
///
/// İma edilen bu sözleşme, üstüne bir ürün mekaniği kurulacak kadar sağlam
/// değil — bu yüzden sıranın **okunduğu tek yer** [orderedInterestsProvider]
/// ve gidiş-dönüş `test/data/interest_order_test.dart` içinde kilitli.
/// Buraya bir gün `HashSet` ya da `union` girerse test kırılır.
final interestsProvider = AsyncNotifierProvider<InterestsNotifier, Set<String>>(
  InterestsNotifier.new,
);

/// Seçili ilgi alanları, **sekme sırasıyla** ve çözülmüş hâlde.
///
/// Tanınmayan kimlik sessizce düşer: eski bir sürümden kalan bir değer
/// yüzünden sekme şeridinde etiketsiz bir boşluk belirmemeli. Aynı davranış
/// `filterByInterests` içinde de var.
final orderedInterestsProvider = Provider<List<Interest>>((ref) {
  final selected = ref.watch(interestsProvider).value;
  if (selected == null) return const [];
  return [for (final id in selected) ?interestById(id)];
});

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
          // Yeni seçim **sona** eklenir: kullanıcının kurduğu sekme sırası,
          // bir konu daha eklendi diye baştan dizilmemeli.
          : {...current, value},
    );
  }

  /// Sekme sırasını değiştirir: [from] konumundaki konu [to] konumuna gider.
  ///
  /// Düz liste anlamı — `removeAt(from)` sonra `insert(to, …)`. Ekran bunu
  /// `ReorderableListView.onReorderItem` ile besliyor; **`onReorder` ile
  /// değil**, çünkü onun verdiği indeks öğe hâlâ listedeymiş gibi hesaplanır
  /// ve her çağıranın elle bir eksiltmesi gerekir. Bir widget sözleşmesinin
  /// veri katmanına sızmaması için düzeltme burada da yapılmıyor: bu metodun
  /// anlamı listenin kendi anlamı.
  void reorder({required int from, required int to}) {
    final current = state.value;
    if (current == null) return;
    if (from == to) return;
    final ordered = current.toList();
    if (from < 0 || from >= ordered.length) return;
    if (to < 0 || to > ordered.length - 1) return;
    ordered.insert(to, ordered.removeAt(from));
    // `LinkedHashSet`: sıra korunur (sınıf başlığındaki nota bakın).
    state = AsyncData(ordered.toSet());
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
/// Sayılar, listeleri besleyen sağlayıcılardan **türetilir** — veritabanını
/// ayrıca saymaz. Öncesinde ayrı sayıyordu ve sonuç şuydu: sayı bir kez
/// kurulup bir daha güncellenmiyordu. Ölçüldü (2026-07-28, cihazda): iki
/// içerik okunduktan sonra `read_history` iki satır tutarken Ayarlar
/// **"0 kayıt"** gösteriyordu. Aynısı kaydetme için de geçerliydi.
///
/// Türetme, tutarlılığı bir alışkanlık olmaktan çıkarıp **yapısal** hâle
/// getiriyor: Ayarlar'daki sayı ile listedeki satır sayısı artık aynı
/// nesneden geliyor, bu yüzden ayrışamazlar.
///
/// Asistan adedi hâlâ depodan okunuyor: o tabloya yazan bir sağlayıcı yok
/// (asistan uygulanmadı) ve sabit `0` yazmak, asistan geldiğinde sessizce
/// yalana dönüşecek bir satır bırakırdı.
final localDataCountsProvider =
    AsyncNotifierProvider<LocalDataCountsNotifier, LocalDataCounts>(
      LocalDataCountsNotifier.new,
    );

final class LocalDataCountsNotifier extends AsyncNotifier<LocalDataCounts> {
  @override
  Future<LocalDataCounts> build() async {
    final saved = await ref.watch(savedItemsProvider.future);
    final history = await ref.watch(readHistoryProvider.future);
    final repository = await ref.watch(localDataRepositoryProvider.future);
    return LocalDataCounts(
      savedItems: saved.length,
      readHistory: history.length,
      assistantConversations:
          (await repository.readCounts()).assistantConversations,
    );
  }

  /// Veritabanı sağlayıcıların **dışında** değiştiğinde (`Verileri Sil`)
  /// adetleri yeniden okur.
  Future<void> reload() async {
    final repository = await ref.read(localDataRepositoryProvider.future);
    state = AsyncData(await repository.readCounts());
  }
}

/// Okuma geçmişi listesi, en yeniden eskiye.
///
/// Ayarlar bu satırın sayısını uzun süredir gösteriyordu ama liste ekranı
/// yoktu: satıra dokunmak "liste ekranı onaylı tasarımda henüz yok" diyen bir
/// SnackBar açıyordu. Veri zaten yazılıyordu; eksik olan yalnız onu gösteren
/// ekrandı.
final readHistoryProvider =
    AsyncNotifierProvider<ReadHistoryNotifier, List<ReadHistoryEntry>>(
      ReadHistoryNotifier.new,
    );

final class ReadHistoryNotifier extends AsyncNotifier<List<ReadHistoryEntry>> {
  @override
  Future<List<ReadHistoryEntry>> build() async {
    final repository = await ref.watch(readHistoryRepositoryProvider.future);
    return repository.readRecent(limit: LocalSchema.readHistoryLimit);
  }

  /// Bir okumayı kaydeder ve listeyi tazeler.
  ///
  /// Yazma **buradan** geçiyor, doğrudan depodan değil. Öncesinde detay ekranı
  /// deposu kendi çağırıyordu ve hiçbir sağlayıcı haberdar olmuyordu; ölçüldü
  /// (2026-07-28, cihazda): iki içerik açıldıktan sonra veritabanında iki satır
  /// vardı ve Ayarlar hâlâ **"0 kayıt"** yazıyordu.
  ///
  /// Yazmadan sonra liste yeniden okunuyor, elle eklenmiyor: depo aynı içeriği
  /// tekilleştiriyor ve 500 satırda buduyor, yani yazmanın sonucu her zaman
  /// "bir satır arttı" değil.
  Future<void> record(String itemId, String? kind) async {
    final repository = await ref.read(readHistoryRepositoryProvider.future);
    await repository.record(itemId, kind);
    state = AsyncData(
      await repository.readRecent(limit: LocalSchema.readHistoryLimit),
    );
  }

  /// Geçmişi siler ve listeyi boşaltır.
  ///
  /// Silme başarısız olursa önceki liste geri konur: kullanıcıya boş bir ekran
  /// gösterip veritabanında satırları bırakmak, iki kaynağın birbirine yalan
  /// söylemesi demekti.
  Future<void> clear() async {
    final previous = state.value ?? const <ReadHistoryEntry>[];
    state = const AsyncData([]);
    try {
      final repository = await ref.read(readHistoryRepositoryProvider.future);
      await repository.clear();
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Veritabanı **dışarıdan** boşaltıldığında listeyi hizalar
  /// (`Verileri Sil`). Yeniden okuma yapılmaz: silme zaten olmuş bitmiştir.
  void reflectExternalClear() => state = const AsyncData([]);
}

/// Kaydedilenler listesi.
///
/// `build` **yalnız okur**; mutasyonlar `invalidate` yerine durumu doğrudan
/// günceller. Bilinçli: TASK-0009'da okuma provider'ı aynı zamanda yazıyor
/// ve ekran silme sonrası `invalidate` çağırıyordu, bu da yerleşmeyen bir
/// okuma/yazma döngüsü üretiyordu. Açılıştaki tek yazma, eski örnek
/// kayıtları silen [SavedItemsSampleCleanup].
final savedItemsProvider =
    AsyncNotifierProvider<SavedItemsNotifier, List<SavedItem>>(
      SavedItemsNotifier.new,
    );

/// Kayıtlı kimlikler — kartların yer imi durumu için.
///
/// Kart kendi `bool`'unu tutmaz: liste tek doğruluk kaynağıdır, yoksa aynı
/// kaydın akıştaki ve Keşfet'teki kartı farklı görünebilir.
final savedItemIdsProvider = Provider<Set<String>>((ref) {
  final items = ref.watch(savedItemsProvider).value;
  if (items == null) return const {};
  return {for (final item in items) item.id};
});

final class SavedItemsNotifier extends AsyncNotifier<List<SavedItem>> {
  @override
  Future<List<SavedItem>> build() async {
    final repository = await ref.watch(savedItemsRepositoryProvider.future);
    return repository.readAll();
  }

  /// Veritabanı başka bir yerden boşaltıldığında ekran durumunu hizalar
  /// (Ayarlar → `Verileri Sil`). Kendisi **yazmaz**.
  void reflectExternalClear() => state = const AsyncData([]);

  /// Feed kaydını kaydeder ya da kaydı kaldırır; sonuç **son** durumdur
  /// (`true` = artık kayıtlı).
  ///
  /// Bu metot 2026-07-28'e kadar **yoktu**: kartlardaki yer imi düğmesi
  /// yalnız kendi `setState`'ini çeviriyor ve "kaydetme yalnız yerel fixture
  /// etkileşimidir" diyen bir snackbar gösteriyordu. Yani kullanıcı hiçbir
  /// şeyi gerçekten kaydedemiyordu ve Kaydedilenler sekmesi yalnız
  /// tohumlanmış örnekleri barındırıyordu.
  Future<bool> toggleFeedItem(FeedItem item) async {
    final previous = state.value;
    if (previous == null) return false;

    final wasSaved = previous.any((saved) => saved.id == item.id);
    final next = wasSaved
        ? previous.where((saved) => saved.id != item.id).toList(growable: false)
        : [
            SavedItem(
              id: item.id,
              // Feed türü olduğu gibi saklanır; kartın rozeti buradan okunur.
              kind: item.kind.name,
              title: item.title,
              sourceLabel: item.sourceName,
              summary: item.summary,
              savedAt: DateTime.now(),
            ),
            ...previous,
          ];

    // İyimser güncelleme: düğme beklemeden döner, yazma başarısız olursa
    // eski liste geri konur ([remove] ile aynı desen).
    state = AsyncData(next);
    try {
      final repository = await ref.read(savedItemsRepositoryProvider.future);
      if (wasSaved) {
        await repository.removeById(item.id);
      } else {
        await repository.add(next.first);
      }
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
    return !wasSaved;
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
