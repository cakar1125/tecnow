import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/design_system/components/app_components.dart';
import 'package:teknoakis/features/explore/explore_screen.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

import '../test_harness.dart';

Widget _explore({double textScale = 1}) =>
    testHarness(const Scaffold(body: ExploreScreen()), textScale: textScale);

Finder _filter(String label) => find.descendant(
  of: find.byKey(const Key('explore-filter-scroll')),
  matching: find.text(label),
);

Future<void> _tapFilter(WidgetTester tester, String label) async {
  final chipLabel = _filter(label);
  await tester.ensureVisible(chipLabel);
  await tester.tap(chipLabel);
  await tester.pump();
}

void main() {
  testWidgets('renders search, five filters, and all section headings', (
    tester,
  ) async {
    await tester.pumpWidget(_explore());

    expect(find.byKey(const Key('explore-search')), findsOneWidget);
    for (final label in [
      'GitHub',
      'AI Modelleri',
      'AI Araçları',
      'Skills',
      'MCP',
    ]) {
      expect(_filter(label), findsOneWidget);
    }
    expect(find.text('En Uygun Sonuçlar'), findsOneWidget);
    expect(find.text('Başlangıç İçin'), findsOneWidget);
    expect(find.text('Popüler'), findsOneWidget);
  });

  testWidgets('search filters result titles and summaries', (tester) async {
    await tester.pumpWidget(_explore());

    await tester.enterText(find.byType(TextField), 'erişilebilir');
    await tester.pump();

    expect(find.text('Örnek Arayüz Pusulası Becerisi'), findsOneWidget);
    expect(find.text('örnek-lab/hayali-akis-kiti'), findsNothing);
  });

  testWidgets('filter chip filters and a second tap clears selection', (
    tester,
  ) async {
    await tester.pumpWidget(_explore());

    await _tapFilter(tester, 'AI Modelleri');

    expect(find.text('Hayalî Kıvılcım Model Kartı'), findsOneWidget);
    expect(find.text('örnek-lab/hayali-akis-kiti'), findsNothing);

    await _tapFilter(tester, 'AI Modelleri');

    expect(find.byType(ExploreResultCard), findsNWidgets(5));
    expect(
      find.byKey(const Key('explore-filter-aiModelleri-idle')),
      findsOneWidget,
    );
  });

  testWidgets('search and filter are applied together', (tester) async {
    await tester.pumpWidget(_explore());

    await _tapFilter(tester, 'Skills');
    await tester.enterText(find.byType(TextField), 'erişilebilir');
    await tester.pump();

    expect(find.byType(ExploreResultCard), findsOneWidget);
    expect(find.text('Örnek Arayüz Pusulası Becerisi'), findsOneWidget);
    expect(find.text('Hayalî Kıvılcım Model Kartı'), findsNothing);
  });

  testWidgets('shows empty state when search has no match', (tester) async {
    await tester.pumpWidget(_explore());

    await tester.enterText(find.byType(TextField), 'eşleşmeyen sorgu');
    await tester.pump();

    expect(find.byKey(const Key('explore-empty-state')), findsOneWidget);
    expect(find.text('Sonuç bulunamadı'), findsOneWidget);
  });

  testWidgets('every result card shows fixture and match explanation markers', (
    tester,
  ) async {
    await tester.pumpWidget(_explore());
    // Kaydırma görünümünde kırpılmış olabilir; çip dokunuşlarıyla aynı desen.
    await tester.ensureVisible(find.text('Tümünü Gör'));
    await tester.pump();
    await tester.tap(find.text('Tümünü Gör'));
    await tester.pump();

    for (final item in exploreResultFixtures) {
      final card = find.byKey(ValueKey(item.id));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('ÖRNEK')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('NEDEN EŞLEŞTİ?')),
        findsOneWidget,
      );
    }
  });

  testWidgets('bookmark toggles and shows local fixture feedback', (
    tester,
  ) async {
    await tester.pumpWidget(_explore());

    await tester.tap(
      find.byKey(const Key('explore-bookmark-hayali-akis-kiti')),
    );
    await tester.pump();

    expect(
      find.text('Kaydetme yalnız yerel fixture etkileşimidir.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('show all clears both the search text and selected filter', (
    tester,
  ) async {
    await tester.pumpWidget(_explore());
    await _tapFilter(tester, 'AI Modelleri');
    await tester.enterText(find.byType(TextField), 'Kıvılcım');
    await tester.pump();

    // Kaydırma görünümünde kırpılmış olabilir; çip dokunuşlarıyla aynı desen.
    await tester.ensureVisible(find.text('Tümünü Gör'));
    await tester.pump();
    await tester.tap(find.text('Tümünü Gör'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    expect(find.byType(ExploreResultCard), findsNWidgets(5));
    for (final filter in ExploreFilter.values) {
      expect(
        find.byKey(Key('explore-filter-${filter.name}-idle')),
        findsOneWidget,
      );
    }
  });

  testWidgets('has no overflow at supported widths and large text', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_explore(textScale: 1.3));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
