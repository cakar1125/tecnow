import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/design_system/components/app_components.dart';
import 'package:tecos/fixtures/fixtures.dart';

import '../test_harness.dart';

void main() {
  testWidgets('AI model card renders clearly marked fixture data', (
    tester,
  ) async {
    await tester.pumpWidget(
      testHarness(const AIModelCard(item: aiModelFixture)),
    );
    expect(find.text('Sentez-2 Mini'), findsOneWidget);
    expect(find.textContaining('128K örnek'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Sentez-2 Mini yapay zekâ modeli kartı',
      ),
      findsOneWidget,
    );
  });
}
