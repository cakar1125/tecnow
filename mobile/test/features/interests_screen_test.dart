import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teknoakis/features/interests/interests_screen.dart';

import '../test_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('interest selection requires at least three choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(testHarness(const InterestsScreen()));

    FilledButton action() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Akışa geç'),
    );
    expect(action().onPressed, isNull);

    for (final label in ['Yapay Zekâ', 'Mobil', 'Açık Kaynak']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(find.text('3/3 seçildi'), findsOneWidget);
    expect(action().onPressed, isNotNull);
  });

  testWidgets('saved interests are restored from local preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_interests': ['Yapay Zekâ', 'Mobil', 'Açık Kaynak'],
    });

    await tester.pumpWidget(testHarness(const InterestsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('3/3 seçildi'), findsOneWidget);
    final action = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Akışa geç'),
    );
    expect(action.onPressed, isNotNull);
  });
}
