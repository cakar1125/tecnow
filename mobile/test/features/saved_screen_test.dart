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

    expect(find.text('Bu filtrede kayıt kalmadı.'), findsOneWidget);
  });

  testWidgets('every card visibly marks fixture transparency', (tester) async {
    await tester.pumpWidget(savedScreenHarness());
    await tester.pumpAndSettle();

    for (final item in savedItemFixtures) {
      await tester.scrollUntilVisible(
        find.text(item.title),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Örnek kayıt'), findsWidgets);
    }
  });

  testWidgets('an empty repository renders the empty state, not an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      memoryDataHarness(
        const Scaffold(body: SafeArea(child: SavedScreen())),
        savedItems: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bu filtrede kayıt kalmadı.'), findsOneWidget);
    expect(find.text('Kayıtlar okunamadı'), findsNothing);
  });
}
