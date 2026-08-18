import 'package:flutter_test/flutter_test.dart';
import '../test_harness.dart';
import 'package:tecos/app/router.dart';

void main() {
  for (final path in ['/create-post', '/notifications', '/profile']) {
    testWidgets('$path shows the router error screen', (tester) async {
      final router = createRouter(initialLocation: path);
      addTearDown(router.dispose);

      await tester.pumpWidget(testRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Sayfa bulunamadı'), findsOneWidget);
    });
  }
}
