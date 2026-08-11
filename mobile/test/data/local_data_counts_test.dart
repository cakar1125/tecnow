import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/data/local/schema.dart';
import 'package:tecos/data/providers.dart';
import 'package:tecos/data/repositories/read_history_repository.dart';
import 'package:tecos/data/repositories/saved_items_repository.dart';

import '../support/test_overrides.dart';

/// Ayarlar'daki adetler, listeleri besleyen sağlayıcılardan türemeli.
///
/// Bu dosyanın var olma sebebi ölçülmüş bir kusur: 28 Temmuz 2026'da cihazda
/// iki içerik açıldı, `read_history` tablosunda **iki satır** oluştu ve Ayarlar
/// ekranı hâlâ **"0 kayıt"** gösteriyordu. Adet sağlayıcısı açılışta bir kez
/// kuruluyor ve veri değiştiğinde kimse ona haber vermiyordu.
///
/// O gün 485 test geçiyordu ve hiçbiri bunu görmedi, çünkü hepsi tek bir
/// karede ölçüyordu: veriyi kur, ekranı çiz, sayıyı oku. Kusur ancak
/// **çizimden sonra veri değişince** ortaya çıkıyor.
void main() {
  ProviderContainer container({
    required SavedItemsRepository saved,
    required ReadHistoryRepository history,
    List<FeedItem>? feed,
  }) {
    final interests = InMemoryInterestsRepository();
    final scope = ProviderContainer(
      overrides: [
        savedItemsRepositoryProvider.overrideWith((ref) async => saved),
        readHistoryRepositoryProvider.overrideWith((ref) async => history),
        interestsRepositoryProvider.overrideWith((ref) async => interests),
        localDataRepositoryProvider.overrideWith(
          (ref) async => InMemoryLocalDataRepository(saved, interests, history),
        ),
        feedRepositoryProvider.overrideWithValue(
          FakeFeedRepository(feed ?? testFeedItems()),
        ),
      ],
    );
    addTearDown(scope.dispose);
    return scope;
  }

  test('reading an item raises the history count without a reload', () async {
    final history = InMemoryReadHistoryRepository();
    final scope = container(
      saved: InMemorySavedItemsRepository(const []),
      history: history,
    );

    // Adet önce okunur: sağlayıcı kurulur ve "0" değerine yerleşir. Kusur
    // tam burada başlıyordu — yerleşen değer bir daha değişmiyordu.
    expect((await scope.read(localDataCountsProvider.future)).readHistory, 0);

    await scope
        .read(readHistoryProvider.notifier)
        .record('0000000000000001', 'repository');

    expect((await scope.read(localDataCountsProvider.future)).readHistory, 1);
  });

  test('saving an item raises the saved count without a reload', () async {
    final saved = InMemorySavedItemsRepository(const []);
    final scope = container(
      saved: saved,
      history: InMemoryReadHistoryRepository(),
    );

    expect((await scope.read(localDataCountsProvider.future)).savedItems, 0);

    await scope
        .read(savedItemsProvider.notifier)
        .toggleFeedItem(testFeedItems().first);

    expect((await scope.read(localDataCountsProvider.future)).savedItems, 1);
  });

  /// Sayı ile liste **aynı nesneden** gelmeli.
  ///
  /// Ayrı ayrı okunduklarında ayrışabiliyorlardı: geçmiş deposu tavanına kadar
  /// tutuyor ama liste sabit 50 okuyordu. Ayarlar "312 kayıt" derken listenin
  /// 50 satır göstermesi mümkündü.
  ///
  /// Tavanı **aşacak kadar** yazılıyor: sınır ısırmazsa bu test sayı/liste
  /// ayrışmasını hiç zorlamaz. Sayılar sabite göreli — 29 Temmuz 2026'da tavan
  /// 500'den 50'ye indiğinde buradaki `120` sabiti kırılmıştı, çünkü tavanın
  /// asla ısırmayacağını varsayıyordu.
  test('the count is exactly the length of the list it describes', () async {
    final history = InMemoryReadHistoryRepository();
    final scope = container(
      saved: InMemorySavedItemsRepository(const []),
      history: history,
    );

    const written = LocalSchema.readHistoryLimit + 70;
    for (var index = 0; index < written; index++) {
      await scope
          .read(readHistoryProvider.notifier)
          .record('kayit-$index', 'skill');
    }

    final counts = await scope.read(localDataCountsProvider.future);
    final entries = await scope.read(readHistoryProvider.future);
    expect(counts.readHistory, entries.length);
    // Tavan gerçekten uygulanıyor: yazılan 120, görünen 50.
    expect(entries, hasLength(LocalSchema.readHistoryLimit));
  });

  /// Aynı içeriği ikinci kez okumak sayıyı artırmamalı: depo tekilleştiriyor
  /// ve sağlayıcı, yazmadan sonra listeyi **yeniden okuyor** — elle bir satır
  /// eklemiyor.
  test('re-reading the same item does not inflate the count', () async {
    final scope = container(
      saved: InMemorySavedItemsRepository(const []),
      history: DeduplicatingReadHistoryRepository(),
    );

    await scope.read(readHistoryProvider.notifier).record('ayni', 'skill');
    await scope.read(readHistoryProvider.notifier).record('ayni', 'skill');

    expect((await scope.read(localDataCountsProvider.future)).readHistory, 1);
  });
}

/// Üretimdeki benzersiz indeksin bellek içi karşılığı.
///
/// [InMemoryReadHistoryRepository] bilinçli olarak tekilleştirmiyor (yazma
/// çağrılarını olduğu gibi sayan testler var), ama tekilleştirmenin adede
/// yansıdığını ölçmek için gereken davranış bu.
final class DeduplicatingReadHistoryRepository
    implements ReadHistoryRepository {
  final _records = <({String itemId, String? kind})>[];

  @override
  Future<void> record(String itemId, String? kind) async {
    _records
      ..removeWhere((existing) => existing.itemId == itemId)
      ..add((itemId: itemId, kind: kind));
  }

  @override
  Future<List<ReadHistoryEntry>> readRecent({int limit = 50}) async => [
    for (var index = 0; index < _records.length && index < limit; index++)
      ReadHistoryEntry(
        id: index,
        itemId: _records[index].itemId,
        kind: _records[index].kind,
        readAt: DateTime(2026, 7, 28),
      ),
  ];

  @override
  Future<void> clear() async => _records.clear();
}
