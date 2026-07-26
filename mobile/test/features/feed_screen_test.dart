import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/features/feed/feed_screen.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

import '../test_harness.dart';

/// FeedScreen uygulamada `AppScaffold` içinde yaşar; SnackBar ve Material
/// etkileşimleri bir Scaffold atası gerektirir. Testler bu gerçeği yansıtır.
Widget _feed({double textScale = 1}) =>
    testHarness(const Scaffold(body: FeedScreen()), textScale: textScale);

/// Sekme etiketleri kart rozetleriyle aynı metni taşıyabilir (örn. "GİTHUB"),
/// bu yüzden sekme beklentileri sekme şeridine daraltılır.
Finder _tab(String label) => find.descendant(
  of: find.byKey(const Key('feed-tab-scroll')),
  matching: find.text(label),
);

void main() {
  testWidgets('feed renders all four tabs', (tester) async {
    await tester.pumpWidget(_feed());

    expect(_tab('SANA ÖZEL'), findsOneWidget);
    expect(_tab('GÜNDEM'), findsOneWidget);
    expect(_tab('GİTHUB'), findsOneWidget);
    expect(_tab('AI MODELLERİ'), findsOneWidget);
  });

  testWidgets('feed starts on Sana Özel with visible cards', (tester) async {
    await tester.pumpWidget(_feed());

    expect(find.byKey(const Key('feed-tab-sanaOzel-selected')), findsOneWidget);
    expect(find.text('örnek-lab/hayali-dalga-motoru'), findsOneWidget);
    expect(find.text('Hayalî Kıvılcım Mini'), findsOneWidget);
  });

  testWidgets('AI Modelleri tab shows only AI fixtures', (tester) async {
    await tester.pumpWidget(_feed());

    await tester.ensureVisible(_tab('AI MODELLERİ'));
    await tester.tap(_tab('AI MODELLERİ'));
    await tester.pump();

    expect(
      find.byKey(const Key('feed-tab-aiModelleri-selected')),
      findsOneWidget,
    );
    expect(find.text('Hayalî Kıvılcım Mini'), findsOneWidget);
    expect(find.text('Örnek Yankı Modeli'), findsOneWidget);
    expect(find.text('örnek-lab/hayali-dalga-motoru'), findsNothing);
    expect(find.text('Hayalî İz Atölyesi'), findsNothing);
  });

  testWidgets('every visible card has fixture and purpose markers', (
    tester,
  ) async {
    await tester.pumpWidget(_feed());

    final visibleItemCount = feedItemFixtures
        .where((item) => item.tabs.contains(FeedTab.sanaOzel))
        .length;
    expect(visibleItemCount, greaterThan(0));
    expect(find.text('ÖRNEK'), findsNWidgets(visibleItemCount));
    expect(find.text('NE İŞE YARAR?'), findsNWidgets(visibleItemCount));
  });

  testWidgets('bookmark toggles and shows local fixture feedback', (
    tester,
  ) async {
    await tester.pumpWidget(_feed());

    await tester.tap(
      find.byKey(const Key('feed-bookmark-hayali-dalga-motoru')),
    );
    await tester.pump();

    expect(
      find.text('Kaydetme yalnız yerel fixture etkileşimidir.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('feed has no overflow at supported sizes and large text', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_feed(textScale: 1.3));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
