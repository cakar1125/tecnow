import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/design_system/components/app_components.dart';

import '../test_harness.dart';

void main() {
  testWidgets('bottom navigation exposes five destinations and selection', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      testHarness(
        Scaffold(
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 0,
            onDestinationSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Keşfet'), findsOneWidget);
    expect(find.text('Asistan'), findsOneWidget);
    expect(find.text('Kaydedilenler'), findsOneWidget);
    expect(find.text('Ayarlar'), findsOneWidget);

    await tester.tap(find.text('Kaydedilenler'));
    expect(selected, 3);
  });
}
