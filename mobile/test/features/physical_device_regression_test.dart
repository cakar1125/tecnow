import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/design_system/components/app_components.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/features/settings/settings_screen.dart';
import 'package:teknoakis/legacy/notifications_screen.dart';

import '../test_harness.dart';

void main() {
  // Switch'ler bu ekrandan kaldırıldı; Android Switch regresyon koruması
  // test/design_system/switch_android_render_test.dart altında yaşıyor.
  testWidgets('settings screen renders on Android without an exception', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(testHarness(const SettingsScreen()));
      expect(find.text('KİŞİSELLEŞTİRME'), findsOneWidget);
      expect(find.text('YEREL VERİLER'), findsOneWidget);
      expect(find.text('GİZLİLİK'), findsOneWidget);
      expect(find.text('HAKKINDA'), findsOneWidget);
      expect(find.text('Verileri Sil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('notification actions provide local feedback', (tester) async {
    await tester.pumpWidget(
      testHarness(const Scaffold(body: NotificationsScreen())),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(
      find.text('Bu bildirim yalnız fixture önizlemesidir.'),
      findsOneWidget,
    );
  });

  testWidgets('social actions provide local feedback', (tester) async {
    await tester.pumpWidget(
      testHarness(const Scaffold(body: SocialActionBar())),
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(
      find.text('Beğen yalnız yerel fixture etkileşimidir.'),
      findsOneWidget,
    );
  });

  testWidgets('Android back returns to the previous onboarding page', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/onboarding/0');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keşfet'), findsOneWidget);
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.text('Kişiselleştir'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Keşfet'), findsOneWidget);
  });
}
