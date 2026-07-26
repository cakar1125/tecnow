import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/design_system/components/app_components.dart';

import '../test_harness.dart';

void main() {
  testWidgets('empty state explains the absence of content', (tester) async {
    await tester.pumpWidget(
      testHarness(
        const EmptyStateView(
          title: 'İçerik yok',
          message: 'Yeni örnekler burada görünür.',
        ),
      ),
    );
    expect(find.text('İçerik yok'), findsOneWidget);
    expect(find.textContaining('Yeni örnekler'), findsOneWidget);
  });

  testWidgets('error state presents message and retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      testHarness(
        ErrorStateView(
          title: 'Bir sorun oluştu',
          message: 'Yerel durum yüklenemedi.',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.tap(find.text('Yeniden dene'));
    expect(retried, isTrue);
  });
}
