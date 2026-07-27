import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/data/app_preferences.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/features/splash/splash_screen.dart';

import '../support/test_overrides.dart';

/// Fiziksel cihaz kabulünde bulunan davranış: uygulama **her** açılışta
/// onboarding gösteriyordu, çünkü splash koşulsuz `/onboarding/0`'a gidiyordu.
/// Bu testler bayrağın iki yönünü de kilitler.
void main() {
  Future<void> pumpSplash(WidgetTester tester) async {
    final router = createRouter(initialLocation: '/splash');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      memoryDataScope(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pump();
    // Marka duraklamasını geç, sonra yönlendirmenin yerleşmesini bekle.
    await tester.pump(SplashScreen.brandPause);
    await tester.pumpAndSettle();
  }

  testWidgets('first launch goes to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpSplash(tester);

    expect(find.text('Keşfet'), findsWidgets);
  });

  testWidgets('a completed onboarding skips straight to the feed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.onboardingCompletedKey: true,
    });

    await pumpSplash(tester);

    expect(find.text('SANA ÖZEL'), findsOneWidget);
  });

  testWidgets('splash cancels its timer when disposed early', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final router = createRouter(initialLocation: '/splash');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      memoryDataScope(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pump();

    // Duraklama dolmadan ağacı değiştir: iptal edilmeyen bir timer burada
    // "Pending timers" hatası verirdi.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(SplashScreen.brandPause);

    expect(tester.takeException(), isNull);
  });
}
