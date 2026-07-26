import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/design_system/components/app_components.dart';
import 'package:teknoakis/design_system/tokens/app_tokens.dart';
import 'package:teknoakis/fixtures/fixtures.dart';

import '../test_harness.dart';

void main() {
  testWidgets('renders the correct label and color for every saved item kind', (
    tester,
  ) async {
    const expectations = {
      SavedItemKind.repository: (
        'REPOSITORY',
        AppColors.primary,
        Icons.code_rounded,
      ),
      SavedItemKind.aiModel: (
        'AI',
        AppColors.aiAccent,
        Icons.psychology_outlined,
      ),
      SavedItemKind.tool: ('ARAÇLAR', AppColors.warning, Icons.build_outlined),
      SavedItemKind.skill: ('SKILLS', AppColors.success, Icons.school_outlined),
      SavedItemKind.assistantProject: (
        'ASİSTAN PROJESİ',
        AppColors.aiAccent,
        Icons.auto_awesome_outlined,
      ),
    };

    for (final entry in expectations.entries) {
      final item = savedItemFixtures.singleWhere(
        (fixture) => fixture.kind == entry.key,
      );
      final (label, color, icon) = entry.value;

      await tester.pumpWidget(
        testHarness(
          SavedItemCard(item: item, onRemove: () {}, onOpenDetails: () {}),
        ),
      );

      expect(find.text(label), findsOneWidget);
      final categoryIcon = tester.widget<Icon>(find.byIcon(icon));
      expect(categoryIcon.color, color);
      expect(find.text('Örnek kayıt'), findsOneWidget);
    }
  });

  testWidgets('renders both actions and invokes their callbacks', (
    tester,
  ) async {
    var removeCalls = 0;
    var detailCalls = 0;

    await tester.pumpWidget(
      testHarness(
        SavedItemCard(
          item: savedItemFixtures.first,
          onRemove: () => removeCalls++,
          onOpenDetails: () => detailCalls++,
        ),
      ),
    );

    expect(find.text('Kaydı Kaldır'), findsOneWidget);
    expect(find.text('Detaya Git'), findsOneWidget);

    await tester.tap(find.text('Kaydı Kaldır'));
    await tester.tap(find.text('Detaya Git'));

    expect(removeCalls, 1);
    expect(detailCalls, 1);
  });
}
