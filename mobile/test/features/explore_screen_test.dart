import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/data/feed/feed_schema.dart';
import 'package:tecnow/design_system/components/app_components.dart';
import 'package:tecnow/features/explore/explore_screen.dart';
import 'package:tecnow/ui/explore_search.dart';

import '../support/test_overrides.dart';

Widget _explore({
  double textScale = 1,
  InMemorySavedItemsRepository? savedRepository,
}) => memoryDataHarness(
  const Scaffold(body: ExploreScreen()),
  savedItems: const [],
  savedRepository: savedRepository,
  textScale: textScale,
);

Finder _filter(String label) => find.descendant(
  of: find.byKey(const Key('explore-filter-scroll')),
  matching: find.text(label),
);

Future<void> _tapFilter(WidgetTester tester, String label) async {
  final chipLabel = _filter(label);
  await tester.ensureVisible(chipLabel);
  await tester.tap(chipLabel);
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

/// Sonuç listesine kapsanmış metin araması.
///
/// Kapsamsız `find.text` yanıltıcı: aynı kayıt hem "En Uygun Sonuçlar"da hem
/// "Popüler"de görünebilir ve iki kez bulunur. Bu doğru davranış, testin
/// yanlış sorusuydu.
Finder _inResults(String text) => find.descendant(
  of: find.byType(ExploreResultCard),
  matching: find.text(text),
);

void main() {
  /// Bu ekran 2026-07-28'e kadar tamamen `lib/fixtures/` okuyordu: arama
  /// hayalî kayıtlar arasında geziniyordu, "NEDEN EŞLEŞTİ?" kutusu fixture'a
  /// yazılmış sabit bir cümleydi ve hiçbir kart hiçbir yere gitmiyordu.
  testWidgets('arama, beş süzgeç ve bölüm başlıkları çizilir', (tester) async {
    await tester.pumpWidget(_explore());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('explore-search')), findsOneWidget);
    for (final filter in ExploreFilter.values) {
      expect(_filter(exploreFilterLabels[filter]!), findsOneWidget);
    }
    expect(find.text('En Uygun Sonuçlar'), findsOneWidget);
    expect(find.text('Başlangıç İçin'), findsOneWidget);
    expect(find.text('Popüler'), findsOneWidget);
  });

  group('gerçek feed', () {
    testWidgets('fixture içeriği hiç sızmaz', (tester) async {
      await tester.pumpWidget(_explore());
      await tester.pumpAndSettle();
      await _tapFilter(tester, 'GitHub');

      expect(find.textContaining('hayalî'), findsNothing);
      expect(find.textContaining('Hayalî'), findsNothing);
      expect(find.textContaining('örnek-lab'), findsNothing);
      expect(find.text('ÖRNEK'), findsNothing);
    });

    testWidgets('varsayılan GitHub süzgeci kaynağa göre süzer', (tester) async {
      await tester.pumpWidget(_explore());
      await tester.pumpAndSettle();

      expect(_inResults('ornek/depo'), findsOneWidget);
      expect(_inResults('ornek/model'), findsNothing);
    });

    testWidgets('süzgeç kaldırılınca akışın tamamı gelir', (tester) async {
      await tester.pumpWidget(_explore());
      await tester.pumpAndSettle();
      await _tapFilter(tester, 'GitHub');

      expect(find.byType(ExploreResultCard), findsNWidgets(3));
    });

    testWidgets('arama başlıkta eşleşir ve gerekçesini söyler', (tester) async {
      await tester.pumpWidget(_explore());
      await tester.pumpAndSettle();
      await _tapFilter(tester, 'GitHub');
      await _search(tester, 'duyuru');

      expect(find.byType(ExploreResultCard), findsOneWidget);
      expect(_inResults('Bir duyuru'), findsOneWidget);
      expect(find.text('NEDEN EŞLEŞTİ?'), findsOneWidget);
      expect(find.text('Başlıkta "duyuru" geçiyor.'), findsOneWidget);
    });

    testWidgets('eşleşme yoksa boş durum gösterilir', (tester) async {
      await tester.pumpWidget(_explore());
      await tester.pumpAndSettle();
      await _search(tester, 'eşleşmeyen sorgu');

      expect(find.byKey(const Key('explore-empty-state')), findsOneWidget);
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
    });

    testWidgets('Tümünü Gör hem aramayı hem süzgeci temizler', (tester) async {
      await tester.pumpWidget(_explore());
      await tester.pumpAndSettle();
      await _search(tester, 'depo');

      await tester.ensureVisible(find.text('Tümünü Gör'));
      await tester.tap(find.text('Tümünü Gör'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
      expect(find.byType(ExploreResultCard), findsNWidgets(3));
      for (final filter in ExploreFilter.values) {
        expect(
          find.byKey(Key('explore-filter-${filter.name}-idle')),
          findsOneWidget,
        );
      }
    });
  });

  /// "Başlangıç İçin" bölümü rehber içeriği gösteriyordu ve feed'de rehber
  /// diye bir kayıt türü yok. Bölüm kaldırılmadı; boşluğun **sebebi**
  /// söyleniyor, çünkü uydurma rehber göstermek de boşluğu gizlemek de yanlış.
  testWidgets('rehber bölümü neden boş olduğunu söyler', (tester) async {
    await tester.pumpWidget(_explore());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('explore-starter-placeholder')),
      findsOneWidget,
    );
    expect(find.text('Rehberler henüz hazır değil'), findsOneWidget);
  });

  testWidgets('popüler bölümü gerçek kayıtları listeler', (tester) async {
    await tester.pumpWidget(_explore());
    await tester.pumpAndSettle();

    expect(find.byType(ExplorePopularRow), findsNWidgets(3));
    expect(find.byKey(const Key('explore-popular-empty')), findsNothing);
  });

  testWidgets('popülerlik sinyali yoksa bölüm bunu söyler', (tester) async {
    await tester.pumpWidget(
      memoryDataHarness(
        const Scaffold(body: ExploreScreen()),
        savedItems: const [],
        feed: [
          testFeedItem(
            id: '0000000000000009',
            kind: FeedItemKind.announcement,
            title: 'Ölçülmemiş duyuru',
            popularity: null,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('explore-popular-empty')), findsOneWidget);
  });

  /// Regresyon kilidi: yer imi düğmesi **gerçekten yazmalı**.
  ///
  /// Eski düğme yalnız kendi `setState`'ini çeviriyordu — yani simgenin
  /// dolduğunu ölçmek yetmez, depoya bakmak gerekir.
  group('kaydetme', () {
    testWidgets('yer imi kaydı depoya yazar', (tester) async {
      final probe = InMemorySavedItemsRepository(const []);
      await tester.pumpWidget(_explore(savedRepository: probe));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('explore-bookmark-0000000000000001')),
      );
      await tester.pumpAndSettle();

      final stored = await probe.readAll();
      expect(stored.map((item) => item.id), ['0000000000000001']);
      expect(stored.single.title, 'ornek/depo');
      expect(stored.single.kind, 'repository');
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('ikinci dokunuş kaydı geri alır', (tester) async {
      final probe = InMemorySavedItemsRepository(const []);
      await tester.pumpWidget(_explore(savedRepository: probe));
      await tester.pumpAndSettle();

      final bookmark = find.byKey(
        const Key('explore-bookmark-0000000000000001'),
      );
      await tester.tap(bookmark);
      await tester.pumpAndSettle();
      await tester.tap(bookmark);
      await tester.pumpAndSettle();

      expect(await probe.readAll(), isEmpty);
      expect(find.byIcon(Icons.bookmark_outline), findsWidgets);
    });
  });

  testWidgets('desteklenen genişliklerde ve büyük yazıda taşma yok', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_explore(textScale: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size taşması');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
