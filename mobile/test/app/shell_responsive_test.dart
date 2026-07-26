import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';

void main() {
  const widths = <double>[360, 390, 430];
  const tabs = <String>[
    '/home',
    '/explore',
    '/assistant',
    '/saved',
    '/settings',
  ];

  for (final width in widths) {
    for (final tab in tabs) {
      testWidgets('$tab renders without overflow at ${width.toInt()}px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final router = createRouter(initialLocation: tab);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: AppTheme.dark,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
