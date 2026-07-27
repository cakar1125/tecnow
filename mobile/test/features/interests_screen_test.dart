import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/data/app_preferences.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/features/interests/interests_screen.dart';

import '../support/test_overrides.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  FilledButton action(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Akışa geç'),
  );

  testWidgets('interest selection requires at least three choices', (
    tester,
  ) async {
    await tester.pumpWidget(memoryDataHarness(const InterestsScreen()));
    await tester.pumpAndSettle();

    expect(action(tester).onPressed, isNull);

    for (final label in ['Yapay Zekâ', 'Mobil', 'Açık Kaynak']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(find.text('3/3 seçildi'), findsOneWidget);
    expect(action(tester).onPressed, isNotNull);
  });

  /// Faz 1'de bu veri `shared_preferences`'tan geliyordu; artık sqflite
  /// tablosu asıl kaynaktır (taşıma: `InterestsMigration`).
  testWidgets('saved interests are restored from the local database', (
    tester,
  ) async {
    await tester.pumpWidget(
      memoryDataHarness(
        const InterestsScreen(),
        interests: const ['Yapay Zekâ', 'Mobil', 'Açık Kaynak'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3/3 seçildi'), findsOneWidget);
    expect(action(tester).onPressed, isNotNull);
  });

  /// Gerçek router ile: hem bayrağın yazıldığını hem akışa geçildiğini ölçer.
  testWidgets('continuing marks onboarding as completed and opens the feed', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/interests');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      memoryDataScope(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        interests: const ['Yapay Zekâ', 'Mobil', 'Açık Kaynak'],
      ),
    );
    await tester.pumpAndSettle();

    final before = await SharedPreferences.getInstance();
    expect(
      before.getBool(AppPreferences.onboardingCompletedKey),
      isNull,
      reason: 'bayrak yalnız akışa geçildiğinde yazılmalı',
    );

    await tester.tap(find.text('Akışa geç'));
    await tester.pumpAndSettle();

    final after = await SharedPreferences.getInstance();
    expect(after.getBool(AppPreferences.onboardingCompletedKey), isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });
}
