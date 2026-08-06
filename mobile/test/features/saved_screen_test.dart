import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/data/feed/feed_schema.dart';
import 'package:tecnow/data/repositories/saved_items_repository.dart';
import 'package:tecnow/features/saved/saved_screen.dart';
import 'package:tecnow/fixtures/fixtures.dart';
import 'package:tecnow/ui/saved_filter.dart';

import '../support/test_overrides.dart';

Widget savedScreenHarness({List<SavedItem>? savedItems}) => memoryDataHarness(
  const Scaffold(body: SafeArea(child: SavedScreen())),
  savedItems: savedItems,
);

void main() {
  testWidgets('initially exposes every saved record card', (tester) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();

    for (final item in savedItemFixtures) {
      await tester.scrollUntilVisible(
        find.text(item.title),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(item.title), findsOneWidget);
    }
  });

  testWidgets('AI filter leaves only AI records', (tester) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'AI'));
    await tester.pump();

    expect(find.text(savedItemFixtures[1].title), findsOneWidget);
    expect(find.text(savedItemFixtures[0].title), findsNothing);
    expect(find.text(savedItemFixtures[2].title), findsNothing);
    expect(find.text(savedItemFixtures[3].title), findsNothing);
    expect(find.text(savedItemFixtures[4].title), findsNothing);
  });

  testWidgets('remove deletes a card and reports a device-local removal', (
    tester,
  ) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();
    final removedTitle = savedItemFixtures.first.title;

    await tester.tap(find.text('Kaydı Kaldır').first);
    await tester.pumpAndSettle();

    expect(find.text(removedTitle), findsNothing);
    expect(find.text('Kayıt bu cihazdan kaldırıldı.'), findsOneWidget);
  });

  testWidgets('removing every record reveals the empty state', (tester) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();

    for (var index = 0; index < savedItemFixtures.length; index++) {
      final removeButton = find.text('Kaydı Kaldır').first;
      await tester.ensureVisible(removeButton);
      await tester.tap(removeButton);
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('saved-none')), findsOneWidget);
  });

  /// Uygulama artık kullanıcının kaydetmediği hiçbir şeyi listeye koymuyor:
  /// tohumlama 2026-07-28'de kaldırıldı. Dolayısıyla "Örnek kayıt" rozeti de
  /// yok — gerçek kayda örnek demek, kurgusal veriyi gerçek gibi sunmanın
  /// ters yönde ama aynı ölçüde yanlış hâliydi.
  testWidgets('hiçbir kartta örnek rozeti kalmaz', (tester) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();

    expect(find.text('Örnek kayıt'), findsNothing);
    expect(find.text('ÖRNEK'), findsNothing);
  });

  /// İlk açılış ile "süzgeç boş" farklı şeyler ve aynı cümleyle anlatılamaz.
  testWidgets('hiç kayıt yokken ilk açılış metni gösterilir', (tester) async {
    await tester.pumpWidget(
      memoryDataHarness(
        const Scaffold(body: SafeArea(child: SavedScreen())),
        savedItems: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-none')), findsOneWidget);
    expect(find.text('Henüz kayıt yok'), findsOneWidget);
    expect(find.byKey(const Key('saved-filter-empty')), findsNothing);
    expect(find.text('Kayıtlar okunamadı'), findsNothing);
  });

  testWidgets('kayıt varken boş süzgeç farklı metin gösterir', (tester) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();

    // Tohum listesinde duyuru kaydı yok; bu çip boş kalır ama **eşleşebilir**
    // bir çiptir. Öncesinde bu test "Asistan Projeleri"ne dokunuyordu — hiçbir
    // türle eşleşemeyen, yani her koşulda boş dönen bir çip. Boş sonucu asla
    // dolamayan bir süzgeçle üretmek, davranışı değil imkânsızlığı ölçmekti.
    await tester.tap(find.widgetWithText(FilterChip, 'Duyurular'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-filter-empty')), findsOneWidget);
    expect(find.byKey(const Key('saved-none')), findsNothing);
  });

  /// Hiçbir türle eşleşemeyen çip **çizilmemeli**.
  ///
  /// "Asistan Projeleri" dokunulduğunda her zaman "Bu filtrede kayıt kalmadı."
  /// diyordu, çünkü asistan hiçbir şey yazmıyor. Ayarlar'daki ölü satırlarla
  /// aynı kalıp: çalışmayan bir kontrol. Asistan uygulandığında
  /// `savedFilterKinds` gerçek bir tür döndürecek ve çip kendiliğinden geri
  /// gelecek.
  testWidgets('eşleşemeyen süzgeç çipi gösterilmez', (tester) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();

    expect(find.text('Asistan Projeleri'), findsNothing);
  });

  /// Akışın en kalabalık türü süzülebilmeli.
  ///
  /// Ölçüldü (2026-07-28): üretilen 200 kaydın 146'sı duyuru. Kaydedilen bir
  /// duyuru yalnız "Tümü" altında görünüyordu — süzgeç şeridinde hiçbir zaman
  /// eşleşmeyen bir çip varken en büyük kategorinin çipi yoktu.
  testWidgets('duyurular süzülebiliyor', (tester) async {
    await tester.pumpWidget(
      savedScreenHarness(
        savedItems: [
          SavedItem(
            id: 'duyuru-1',
            kind: FeedItemKind.announcement.name,
            title: 'Bir duyuru',
            savedAt: DateTime(2026, 7, 28),
          ),
          SavedItem(
            id: 'depo-1',
            kind: FeedItemKind.repository.name,
            title: 'Bir depo',
            savedAt: DateTime(2026, 7, 27),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Duyurular'));
    await tester.pumpAndSettle();

    expect(find.text('Bir duyuru'), findsOneWidget);
    expect(find.text('Bir depo'), findsNothing);
  });

  group('savedFilterKinds', () {
    test('araçlar çipi MCP sunucularını da alır', () {
      expect(savedFilterKinds(SavedFilter.tool), {
        FeedItemKind.tool,
        FeedItemKind.mcp,
      });
    });

    test('her görünür çipin eşleşebileceği bir tür var', () {
      for (final filter in visibleSavedFilters) {
        expect(
          savedFilterKinds(filter),
          isNotEmpty,
          reason: '${savedFilterLabels[filter]} hiçbir şeyle eşleşemiyor',
        );
      }
    });

    /// Her feed türü en az bir çipten erişilebilmeli — yoksa kaydedilen bir
    /// içerik "Tümü" dışında hiçbir yerde bulunamaz.
    test('her feed türü bir çipe düşüyor', () {
      final covered = {
        for (final filter in visibleSavedFilters) ...savedFilterKinds(filter),
      };
      expect(covered, containsAll(FeedItemKind.values));
    });
  });
}
