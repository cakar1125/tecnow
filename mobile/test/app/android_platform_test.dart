import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/app/router.dart';
import 'package:tecnow/design_system/theme/app_theme.dart';
import 'package:tecnow/features/settings/settings_screen.dart';

import '../test_harness.dart';

/// Android'e özgü davranışlar.
///
/// Bu iki test `physical_device_regression_test.dart` içinden çıkarıldı
/// (2026-07-28). O dosyanın adı "fiziksel cihaz regresyonu" diyordu ama
/// dört testinin ikisi `lib/legacy/` altındaki, **yönlendiricide olmayan**
/// ekranları ölçüyordu. Süite bakan biri cihaz davranışının kapsandığını
/// sanıyordu; gerçekte yarısı kullanıcının ulaşamayacağı kodu ölçüyordu.
/// Testler silinmedi, ayrıldı — bkz. `test/legacy/legacy_screens_test.dart`.
void main() {
  // Switch'ler bu ekrandan kaldırıldı; Android Switch regresyon koruması
  // `test/design_system/switch_android_render_test.dart` altında yaşıyor.
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

  /// Onboarding adımları arasında `push` kullanılıyor; Android'in sistem geri
  /// hareketi bu yüzden bir önceki adıma dönmeli. `go` kullanılsaydı geri
  /// tuşu uygulamadan çıkardı.
  testWidgets('Android back returns to the previous onboarding page', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/onboarding/0');
    addTearDown(router.dispose);
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
