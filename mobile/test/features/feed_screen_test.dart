import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/features/feed/feed_screen.dart';

import '../test_harness.dart';

void main() {
  testWidgets('feed renders repository, AI model and technology fixtures', (
    tester,
  ) async {
    await tester.pumpWidget(testHarness(const FeedScreen()));
    expect(find.text('örnek-lab/akış-motoru'), findsOneWidget);
    expect(find.text('Sentez-2 Mini'), findsOneWidget);
    expect(find.text('Bugünün gelişmeleri'), findsOneWidget);
  });

  testWidgets('feed has no overflow at supported sizes and large text', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(testHarness(const FeedScreen(), textScale: 1.3));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
