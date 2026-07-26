import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/design_system/components/app_components.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

import '../test_harness.dart';

void main() {
  testWidgets('repository card renders fixture metrics', (tester) async {
    await tester.pumpWidget(
      testHarness(const RepositoryCard(item: repositoryFixture)),
    );
    expect(find.textContaining('12,8K'), findsOneWidget);
    expect(find.textContaining('Dart'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'örnek-lab/akış-motoru repository kartı',
      ),
      findsOneWidget,
    );
  });
}
