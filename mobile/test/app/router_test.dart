import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/app/router.dart';
import 'package:tecos/design_system/theme/app_theme.dart';

import '../support/test_overrides.dart';

void main() {
  testWidgets('router changes shell tabs and exposes detail routes', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      memoryDataScope(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SANA ÖZEL'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/home');

    Finder navigationLabel(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

    await tester.tap(navigationLabel('Keşfet'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/explore');

    await tester.tap(navigationLabel('Asistan'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/assistant');

    await tester.tap(navigationLabel('Kaydedilenler'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/saved');

    await tester.tap(navigationLabel('Ayarlar'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/settings');

    // Tek detay rotası: başlık kaydın türünden gelir, rotadan değil.
    router.push('/icerik/0000000000000001');
    await tester.pumpAndSettle();
    expect(find.text('Repository Detayı'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    router.push('/icerik/0000000000000003');
    await tester.pumpAndSettle();
    expect(find.text('Duyuru Detayı'), findsOneWidget);
  });
}
