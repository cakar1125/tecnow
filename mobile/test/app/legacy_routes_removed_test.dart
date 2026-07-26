import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';

void main() {
  for (final path in ['/create-post', '/notifications', '/profile']) {
    testWidgets('$path shows the router error screen', (tester) async {
      final router = createRouter(initialLocation: path);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sayfa bulunamadı'), findsOneWidget);
    });
  }
}
