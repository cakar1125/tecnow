import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tecos/data/feed/feed_repository.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/data/providers.dart';
import 'package:tecos/data/repositories/interests_repository.dart';
import 'package:tecos/data/repositories/local_data_repository.dart';
import 'package:tecos/data/repositories/read_history_repository.dart';
import 'package:tecos/data/repositories/saved_items_repository.dart';
import 'package:tecos/fixtures/fixtures.dart';

import '../test_harness.dart';

/// Widget testleri için bellek içi kayıt deposu.
///
/// sqflite'a hiç dokunmaz: widget testlerinde ne `sqflite_common_ffi` kurulumu
/// ne de dosya erişimi gerekir, davranış tamamen belirlenimcidir. Gerçek
/// veritabanı kalıcılığı ayrıca `test/data/saved_persistence_test.dart`
/// içinde ölçülür.
final class InMemorySavedItemsRepository implements SavedItemsRepository {
  InMemorySavedItemsRepository(List<SavedItem> initial)
    : _items = List.of(initial);

  final List<SavedItem> _items;

  @override
  Future<List<SavedItem>> readAll() async => List.unmodifiable(_items);

  @override
  Future<void> add(SavedItem item) async {
    _items
      ..removeWhere((existing) => existing.id == item.id)
      ..add(item);
  }

  @override
  Future<void> removeById(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clear() async => _items.clear();
}

final class InMemoryInterestsRepository implements InterestsRepository {
  InMemoryInterestsRepository([List<String> initial = const []])
    : _interests = List.of(initial);

  List<String> _interests;

  @override
  Future<List<String>> readAll() async => List.unmodifiable(_interests);

  @override
  Future<void> replaceAll(List<String> interests) async {
    _interests = List.of(interests);
  }

  @override
  Future<void> clear() async => _interests = [];
}

final class InMemoryReadHistoryRepository implements ReadHistoryRepository {
  final List<({String itemId, String? kind})> records = [];

  @override
  Future<void> record(String itemId, String? kind) async =>
      records.add((itemId: itemId, kind: kind));

  @override
  Future<List<ReadHistoryEntry>> readRecent({int limit = 50}) async => [
    for (var index = 0; index < records.length && index < limit; index++)
      ReadHistoryEntry(
        id: index,
        itemId: records[index].itemId,
        kind: records[index].kind,
        readAt: DateTime(2026, 7, 27),
      ),
  ];

  @override
  Future<void> clear() async => records.clear();
}

/// Diğer bellek içi depoların üstüne oturur: `Verileri Sil` gerçekten
/// hepsini boşaltmalı ve adetler bunu yansıtmalıdır.
final class InMemoryLocalDataRepository implements LocalDataRepository {
  InMemoryLocalDataRepository(this._saved, this._interests, this._history);

  final SavedItemsRepository _saved;
  final InterestsRepository _interests;
  final ReadHistoryRepository _history;

  @override
  Future<void> deleteEverything() async {
    await _saved.clear();
    await _interests.clear();
    await _history.clear();
  }

  @override
  Future<LocalDataCounts> readCounts() async => LocalDataCounts(
    savedItems: (await _saved.readAll()).length,
    readHistory: (await _history.readRecent(limit: 1000)).length,
    // Asistan konuşmaları henüz hiçbir yerde yazılmıyor; üretimde de tablo boş.
    assistantConversations: 0,
  );
}

/// Kaydedilenler ekranının varsayılan test verisi.
///
/// Üretimde artık **tohumlama yok**: uygulama kullanıcının kaydetmediği
/// hiçbir şeyi listeye koymaz (bkz. `SavedItemsSampleCleanup`). Bu liste
/// yalnız "dolu liste" hâlini ölçen testler için var; boş hâli ölçen testler
/// `savedItems: const []` geçer.
///
/// Sıra `savedAt DESC`: beklenen kart sırası tesadüfen tutmasın.
List<SavedItem> seededSavedItems() {
  final seededAt = DateTime(2026, 7, 27, 12);
  return [
    for (var index = 0; index < savedItemFixtures.length; index++)
      SavedItem(
        id: savedItemFixtures[index].id,
        kind: savedItemFixtures[index].kind.name,
        title: savedItemFixtures[index].title,
        sourceLabel: savedItemFixtures[index].sourceLabel,
        summary: savedItemFixtures[index].summary,
        savedAt: seededAt.subtract(Duration(milliseconds: index)),
      ),
  ];
}

/// Veri katmanına bağlı ekranları render eden testler için hazır kabuk.
///
/// `Override` tipi Riverpod 3'ün genel API'sinden dışa aktarılmadığı için
/// override listesi bir değişkende adlandırılamaz; bu yüzden yardımcı,
/// liste değil doğrudan widget döndürür.
Widget memoryDataHarness(
  Widget child, {
  List<SavedItem>? savedItems,
  SavedItemsRepository? savedRepository,
  List<String>? interests,
  InMemoryInterestsRepository? interestsRepository,
  ReadHistoryRepository? readHistory,
  List<FeedItem>? feed,
  FeedRepository? feedRepository,
  UrlOpener? urlOpener,
  Set<String>? mutedSources,
  double textScale = 1,
}) => memoryDataScope(
  testApp(child, textScale: textScale),
  savedItems: savedItems,
  savedRepository: savedRepository,
  interests: interests,
  interestsRepository: interestsRepository,
  readHistory: readHistory,
  feed: feed,
  feedRepository: feedRepository,
  urlOpener: urlOpener,
  mutedSources: mutedSources,
);

/// Router'ı kendisi kuran testler için: yalnız scope, kendi `MaterialApp`'ini
/// getiren çağıranlar kullanır.
Widget memoryDataScope(
  Widget child, {
  List<SavedItem>? savedItems,
  SavedItemsRepository? savedRepository,
  List<String>? interests,

  /// Çağıran depoyu elinde tutmak istediğinde: bir seçimin gerçekten
  /// **yazıldığını** ölçmek için ekrandaki duruma değil depoya bakmak
  /// gerekiyor ([savedRepository] ile aynı gerekçe).
  InMemoryInterestsRepository? interestsRepository,
  ReadHistoryRepository? readHistory,
  List<FeedItem>? feed,
  FeedRepository? feedRepository,
  UrlOpener? urlOpener,

  /// Akıştan çıkarılmış kaynaklar. Uygulamada `bootstrap` diskten okuyup
  /// `runApp`'ten önce yerine koyuyor; testte aynı işi bu parametre yapar.
  Set<String>? mutedSources,
}) {
  // Örnekler önceden kurulur: `localDataRepositoryProvider` diğer üçüyle
  // **aynı** nesneleri görmeli, yoksa "Verileri Sil" testte hiçbir şeyi
  // boşaltmamış gibi görünür.
  //
  // [savedRepository] verilirse çağıran onu elinde tutar: kaydetmenin
  // gerçekten **yazdığını** ölçmek için depoya bakmak gerekiyor, ekrandaki
  // simgenin dolması yetmez (eski sahte düğme de simgeyi dolduruyordu).
  final saved =
      savedRepository ??
      InMemorySavedItemsRepository(savedItems ?? seededSavedItems());
  final interestsStore =
      interestsRepository ?? InMemoryInterestsRepository(interests ?? const []);
  final history = readHistory ?? InMemoryReadHistoryRepository();

  return ProviderScope(
    overrides: [
      savedItemsRepositoryProvider.overrideWith((ref) async => saved),
      interestsRepositoryProvider.overrideWith((ref) async => interestsStore),
      readHistoryRepositoryProvider.overrideWith((ref) async => history),
      localDataRepositoryProvider.overrideWith(
        (ref) async =>
            InMemoryLocalDataRepository(saved, interestsStore, history),
      ),
      feedRepositoryProvider.overrideWithValue(
        feedRepository ?? FakeFeedRepository(feed ?? testFeedItems()),
      ),
      // Testler gerçek tarayıcı açmaz; varsayılan olarak "açıldı" der.
      urlOpenerProvider.overrideWithValue(urlOpener ?? (url) async => true),
      if (mutedSources != null)
        initialMutedSourcesProvider.overrideWithValue(mutedSources),
    ],
    child: child,
  );
}

/// Feed'in okunamadığı durumu kuran kabuk. Ekranların "içerik yok" ile
/// "içerik okunamadı"yı ayırdığını doğrulamak için.
///
/// [memoryDataScope] üzerinden kuruluyor: yalnız feed'i override etmek
/// yetmiyordu, çünkü ekranlar okuma geçmişi de yazıyor ve o çağrı gerçek
/// sqflite'a düşüp ekranı hiç yerleştirmiyordu.
Widget memoryDataScopeWithFailingFeed(Widget child) => memoryDataScope(
  child,
  feedRepository: FakeFeedRepository(
    const [],
    error: const FeedFormatException('bozuk'),
  ),
);

/// Paketlenmiş dosyaya dokunmayan feed deposu.
///
/// Ekran testleri **gerçek** `assets/feed/feed.json`'ı okumamalı: o dosya her
/// üretici koşusunda değişir ve testler o günkü içeriğe bağlı olurdu. Gerçek
/// varlığın ayrıştırılabildiği ayrıca `test/data/feed_repository_test.dart`
/// içinde ölçülüyor.
final class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository(
    this.items, {
    this.error,
    this.syncOutcome,
    this.lastSync,
    this.remoteEnabled = false,
    this.stale = false,
    this.language = feedDefaultLanguage,
    this.availableLanguages = const [],
  });

  final List<FeedItem> items;

  /// Verilirse [load] bunu fırlatır — hata durumu ekranları için.
  final Object? error;

  /// Verilirse [refresh] bunu döndürür. Ağ katmanı gerçekten kurulmaz:
  /// ekranların sonuca **nasıl tepki verdiği** ölçülür, ağın kendisi değil.
  ///
  /// Değiştirilebilir: art arda gelen iki denemenin farklı sonuçlanması
  /// (önce hata, sonra başarı) tek başına ölçülmesi gereken bir davranış.
  FeedSyncOutcome? syncOutcome;

  final DateTime? lastSync;

  @override
  final bool remoteEnabled;

  /// Açılışta kendiliğinden tazeleme yapılıp yapılmadığını ölçmek için.
  final bool stale;

  /// Kaç kez tazeleme istendiği. Açılışta bayat içeriğin bir kez — ve yalnız
  /// bir kez — tazelenmesini ölçmek için.
  int refreshCount = 0;

  /// Yayının dili ve sunduğu diller. Ayarlar ekranının dil satırı buna
  /// bakarak şekil değiştiriyor; varsayılan boş liste "tek dil" demek ve
  /// bugünkü gerçek yayının durumu bu.
  final String language;
  final List<FeedLanguage> availableLanguages;

  @override
  Future<Feed> load() async {
    if (error case final failure?) throw failure;
    return testFeed(
      items,
      language: language,
      availableLanguages: availableLanguages,
    );
  }

  @override
  Future<FeedSyncOutcome> refresh() async {
    refreshCount++;
    return syncOutcome ?? FeedSyncOutcome.disabled;
  }

  @override
  Future<DateTime?> lastSyncAt() async => lastSync;

  @override
  Future<bool> isStale() async => stale;
}

Feed testFeed(
  List<FeedItem> items, {
  DateTime? generatedAt,
  Duration refreshAfter = feedDefaultRefreshAfter,
  String language = feedDefaultLanguage,
  List<FeedLanguage> availableLanguages = const [],
}) => Feed(
  schemaVersion: feedSchemaVersion,
  generatedAt: generatedAt ?? DateTime.utc(2026, 7, 27),
  items: items,
  refreshAfter: refreshAfter,
  language: language,
  availableLanguages: availableLanguages,
);

/// Ekran testlerinin belirlenimci feed'i.
///
/// Her sekmenin dolu olması için türler bilinçli olarak dağıtıldı: depo,
/// AI modeli ve duyuru.
List<FeedItem> testFeedItems() => [
  testFeedItem(
    id: '0000000000000001',
    kind: FeedItemKind.repository,
    title: 'ornek/depo',
    topics: const ['dart'],
  ),
  testFeedItem(
    id: '0000000000000002',
    kind: FeedItemKind.aiModel,
    title: 'ornek/model',
    sourceKind: FeedSourceKind.huggingFace,
    sourceName: 'Hugging Face',
    summaryOrigin: SummaryOrigin.generated,
    language: 'tr',
    topics: const ['llm'],
  ),
  testFeedItem(
    id: '0000000000000003',
    kind: FeedItemKind.announcement,
    title: 'Bir duyuru',
    sourceKind: FeedSourceKind.officialBlog,
    sourceName: 'OpenAI Blog',
    publishedAt: DateTime.utc(2026, 7, 26),
  ),
];

FeedItem testFeedItem({
  required String id,
  required FeedItemKind kind,
  required String title,
  String summary = 'Bir açıklama.',
  SummaryOrigin summaryOrigin = SummaryOrigin.original,
  String sourceName = 'GitHub',
  FeedSourceKind sourceKind = FeedSourceKind.github,
  String language = 'en',
  List<String> topics = const [],
  DateTime? publishedAt,
  DateTime? retractedAt,
  int? popularity = 10,
}) => FeedItem(
  retractedAt: retractedAt,
  id: id,
  kind: kind,
  title: title,
  summary: summary,
  summaryOrigin: summaryOrigin,
  sourceName: sourceName,
  sourceKind: sourceKind,
  url: Uri.parse('https://github.com/ornek/$id'),
  publishedAt: publishedAt ?? DateTime.utc(2026, 7, 20),
  checkedAt: DateTime.utc(2026, 7, 27),
  language: language,
  trust: TrustSignals(
    officialSource: true,
    hasLicense: true,
    recentlyUpdated: true,
    maintained: true,
    popularity: popularity,
  ),
  topics: topics,
);
