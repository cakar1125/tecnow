import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teknoakis/data/providers.dart';
import 'package:teknoakis/data/repositories/interests_repository.dart';
import 'package:teknoakis/data/repositories/read_history_repository.dart';
import 'package:teknoakis/data/repositories/saved_items_repository.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

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

/// `SavedItemsSeeder`'ın üreteceği listenin aynısı.
///
/// Testler üretimdeki tohum sırasını (`savedAt DESC`) taklit etmelidir; aksi
/// halde beklenen kart sırası testte tesadüfen tutar.
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
  List<String>? interests,
  ReadHistoryRepository? readHistory,
  double textScale = 1,
}) => memoryDataScope(
  testApp(child, textScale: textScale),
  savedItems: savedItems,
  interests: interests,
  readHistory: readHistory,
);

/// Router'ı kendisi kuran testler için: yalnız scope, kendi `MaterialApp`'ini
/// getiren çağıranlar kullanır.
Widget memoryDataScope(
  Widget child, {
  List<SavedItem>? savedItems,
  List<String>? interests,
  ReadHistoryRepository? readHistory,
}) => ProviderScope(
  overrides: [
    savedItemsRepositoryProvider.overrideWith(
      (ref) async =>
          InMemorySavedItemsRepository(savedItems ?? seededSavedItems()),
    ),
    interestsRepositoryProvider.overrideWith(
      (ref) async => InMemoryInterestsRepository(interests ?? const []),
    ),
    readHistoryRepositoryProvider.overrideWith(
      (ref) async => readHistory ?? InMemoryReadHistoryRepository(),
    ),
  ],
  child: child,
);
