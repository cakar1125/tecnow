import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/features/saved/saved_screen.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

import '../test_harness.dart';

Widget savedScreenHarness() =>
    testHarness(const Scaffold(body: SafeArea(child: SavedScreen())));

void main() {
  testWidgets('initially exposes every saved fixture card', (tester) async {
    await tester.pumpWidget(savedScreenHarness());

    for (final item in savedItemFixtures) {
      await tester.scrollUntilVisible(
        find.text(item.title),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(item.title), findsOneWidget);
    }
  });

  testWidgets('AI filter leaves only AI fixtures', (tester) async {
    await tester.pumpWidget(savedScreenHarness());

    await tester.tap(find.widgetWithText(FilterChip, 'AI'));
    await tester.pump();

    expect(find.text(savedItemFixtures[1].title), findsOneWidget);
    expect(find.text(savedItemFixtures[0].title), findsNothing);
    expect(find.text(savedItemFixtures[2].title), findsNothing);
    expect(find.text(savedItemFixtures[3].title), findsNothing);
    expect(find.text(savedItemFixtures[4].title), findsNothing);
  });

  testWidgets('remove deletes a card and shows fixture-only feedback', (
    tester,
  ) async {
    await tester.pumpWidget(savedScreenHarness());
    final removedTitle = savedItemFixtures.first.title;

    await tester.tap(find.text('Kaydı Kaldır').first);
    await tester.pump();

    expect(find.text(removedTitle), findsNothing);
    expect(
      find.text('Kaydı kaldırma yalnız yerel fixture etkileşimidir.'),
      findsOneWidget,
    );
  });

  testWidgets('removing all fixtures reveals the empty state', (tester) async {
    await tester.pumpWidget(savedScreenHarness());

    for (var index = 0; index < savedItemFixtures.length; index++) {
      final removeButton = find.text('Kaydı Kaldır').first;
      await tester.ensureVisible(removeButton);
      await tester.tap(removeButton);
      await tester.pump();
    }

    expect(find.text('Bu filtrede kayıt kalmadı.'), findsOneWidget);
  });

  testWidgets('every card visibly marks fixture transparency', (tester) async {
    await tester.pumpWidget(savedScreenHarness());

    for (final item in savedItemFixtures) {
      await tester.scrollUntilVisible(
        find.text(item.title),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Örnek kayıt'), findsWidgets);
    }
  });
}
