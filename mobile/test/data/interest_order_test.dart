/// Sekme sırasının **gidiş-dönüşü**.
///
/// Ana Sayfa'nın sekme şeridi `interestsProvider`'daki kümenin dolaşım
/// sırasına dayanıyor. `Set` tipi sıra vaat etmez; zincir Dart'ın küme
/// değişmezlerinin `LinkedHashSet` üretmesi sayesinde çalışıyor. İma edilen
/// bir sözleşme üstüne kurulmuş bir ürün mekaniği, yazılı bir kapı olmadan
/// sessizce bozulur — bu dosya o kapı.
///
/// Kırılması gereken hâller: kümeye `HashSet` girmesi, [InterestsNotifier]
/// içinde `union`/`addAll` gibi sırayı korumayan bir birleştirme, ya da
/// deponun `createdAt` yerine ada göre sıralaması.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/interests/interest_taxonomy.dart';
import 'package:tecos/data/providers.dart';

import '../support/test_overrides.dart';

/// Sağlayıcıları bellek içi bir ilgi alanı deposuyla kurar.
({ProviderContainer container, InMemoryInterestsRepository repository}) _setUp(
  List<String> initial,
) {
  final repository = InMemoryInterestsRepository(initial);
  final container = ProviderContainer(
    overrides: [
      interestsRepositoryProvider.overrideWith((ref) async => repository),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, repository: repository);
}

void main() {
  group('okuma sırası', () {
    test('depodaki sıra korunur', () async {
      final harness = _setUp(const ['oyun', 'bulut', 'yapay-zeka']);

      final selected = await harness.container.read(interestsProvider.future);

      expect(selected.toList(), ['oyun', 'bulut', 'yapay-zeka']);
    });

    test('çözülmüş liste aynı sırayı taşır', () async {
      final harness = _setUp(const ['oyun', 'bulut', 'yapay-zeka']);
      await harness.container.read(interestsProvider.future);

      final ordered = harness.container.read(orderedInterestsProvider);

      expect(ordered.map((interest) => interest.id), [
        'oyun',
        'bulut',
        'yapay-zeka',
      ]);
    });

    /// Eski bir sürümden kalan bir kimlik yüzünden sekme şeridinde etiketsiz
    /// bir boşluk belirmemeli.
    test('tanınmayan kimlik sessizce düşer', () async {
      final harness = _setUp(const ['bulut', 'yok-boyle-alan', 'oyun']);
      await harness.container.read(interestsProvider.future);

      expect(
        harness.container.read(orderedInterestsProvider).map((i) => i.id),
        ['bulut', 'oyun'],
      );
    });

    test('yükleme bitmeden liste boştur, atmaz', () {
      final harness = _setUp(const ['bulut']);

      expect(harness.container.read(orderedInterestsProvider), isEmpty);
    });
  });

  group('sıralama', () {
    test('öğe aşağı taşınır', () async {
      final harness = _setUp(const ['a-yok', 'bulut', 'oyun', 'mobil']);
      await harness.container.read(interestsProvider.future);

      harness.container
          .read(interestsProvider.notifier)
          .reorder(from: 1, to: 3);

      expect(harness.container.read(interestsProvider).value!.toList(), [
        'a-yok',
        'oyun',
        'mobil',
        'bulut',
      ]);
    });

    test('öğe yukarı taşınır', () async {
      final harness = _setUp(const ['bulut', 'oyun', 'mobil']);
      await harness.container.read(interestsProvider.future);

      harness.container
          .read(interestsProvider.notifier)
          .reorder(from: 2, to: 0);

      expect(harness.container.read(interestsProvider).value!.toList(), [
        'mobil',
        'bulut',
        'oyun',
      ]);
    });

    test('aynı konuma taşımak hiçbir şeyi değiştirmez', () async {
      final harness = _setUp(const ['bulut', 'oyun']);
      await harness.container.read(interestsProvider.future);

      harness.container
          .read(interestsProvider.notifier)
          .reorder(from: 1, to: 1);

      expect(harness.container.read(interestsProvider).value!.toList(), [
        'bulut',
        'oyun',
      ]);
    });

    /// Aralık dışı bir indeks atmaz: sürükleme sırasında liste değişebilir
    /// (Keşfet'ten konu kapatılması) ve bir jest yüzünden uygulama
    /// çökmemeli.
    test('aralık dışı indeks yok sayılır', () async {
      final harness = _setUp(const ['bulut', 'oyun']);
      await harness.container.read(interestsProvider.future);
      final notifier = harness.container.read(interestsProvider.notifier);

      notifier.reorder(from: 5, to: 0);
      notifier.reorder(from: 0, to: 9);
      notifier.reorder(from: -1, to: 0);

      expect(harness.container.read(interestsProvider).value!.toList(), [
        'bulut',
        'oyun',
      ]);
    });

    /// Yeni bir konu sona eklenir: kullanıcının kurduğu sıra, bir konu daha
    /// seçildi diye baştan dizilmemeli.
    test('yeni seçim sıranın sonuna gider', () async {
      final harness = _setUp(const ['bulut', 'oyun']);
      await harness.container.read(interestsProvider.future);

      harness.container.read(interestsProvider.notifier).toggle('mobil');

      expect(harness.container.read(interestsProvider).value!.toList(), [
        'bulut',
        'oyun',
        'mobil',
      ]);
    });

    /// Bir konuyu kapatıp geri açmak diğerlerinin sırasını bozmamalı.
    test('kapatma kalan sıraya dokunmaz', () async {
      final harness = _setUp(const ['bulut', 'oyun', 'mobil']);
      await harness.container.read(interestsProvider.future);

      harness.container.read(interestsProvider.notifier).toggle('oyun');

      expect(harness.container.read(interestsProvider).value!.toList(), [
        'bulut',
        'mobil',
      ]);
    });
  });

  /// Asıl kapı: sıra **diske gidip geri geliyor mu**. Yalnız bellekte
  /// çalışan bir sıralama, uygulama kapanınca kaybolur.
  group('kalıcılık', () {
    test('sıralanan liste diske aynı sırayla yazılır', () async {
      final harness = _setUp(const ['bulut', 'oyun', 'mobil']);
      await harness.container.read(interestsProvider.future);
      final notifier = harness.container.read(interestsProvider.notifier);

      notifier.reorder(from: 2, to: 0);
      await notifier.persist();

      expect(await harness.repository.readAll(), ['mobil', 'bulut', 'oyun']);
    });

    test('yeniden okunduğunda sıra korunur', () async {
      final harness = _setUp(const ['bulut', 'oyun', 'mobil']);
      await harness.container.read(interestsProvider.future);
      final notifier = harness.container.read(interestsProvider.notifier);
      notifier.reorder(from: 2, to: 0);
      await notifier.persist();

      // İkinci bir oturum: aynı depo, yeni sağlayıcı ağacı.
      final second = ProviderContainer(
        overrides: [
          interestsRepositoryProvider.overrideWith(
            (ref) async => harness.repository,
          ),
        ],
      );
      addTearDown(second.dispose);
      await second.read(interestsProvider.future);

      expect(second.read(orderedInterestsProvider).map((i) => i.id), [
        'mobil',
        'bulut',
        'oyun',
      ]);
    });
  });

  /// Sözlükteki kimlikler sekme kimliği olarak da kullanılıyor; sabit
  /// sekmelerin kimlikleriyle çakışsalardı şerit iki sekmeyi aynı sayardı.
  test('konu kimlikleri sabit sekme kimlikleriyle çakışmaz', () {
    final ids = {for (final interest in interestTaxonomy) interest.id};

    expect(ids, isNot(contains('sana-ozel')));
    expect(ids, isNot(contains('tumu')));
  });
}
