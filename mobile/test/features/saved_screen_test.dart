import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/features/saved/saved_screen.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

import '../support/test_overrides.dart';

Widget savedScreenHarness() =>
    memoryDataHarness(const Scaffold(body: SafeArea(child: SavedScreen())));

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

    // Tohum listesinde asistan projesi kaydı yok; bu çip boş kalır.
    await tester.tap(find.widgetWithText(FilterChip, 'Asistan Projeleri'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-filter-empty')), findsOneWidget);
    expect(find.byKey(const Key('saved-none')), findsNothing);
  });
}
