import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/design_system/tokens/app_tokens.dart';

Future<void> pumpSettingsScreen(WidgetTester tester) async {
  final router = createRouter(initialLocation: '/settings');
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows all four settings sections', (tester) async {
    await pumpSettingsScreen(tester);

    for (final heading in [
      'KİŞİSELLEŞTİRME',
      'YEREL VERİLER',
      'GİZLİLİK',
      'HAKKINDA',
    ]) {
      expect(find.text(heading), findsOneWidget);
    }
  });

  testWidgets('renders the delete-data row with the critical color', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);

    final deleteLabel = tester.widget<Text>(find.text('Verileri Sil'));
    expect(deleteLabel.style?.color, AppColors.critical);

    final deleteIcon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
    expect(deleteIcon.color, AppColors.critical);
  });

  testWidgets('delete-data confirmation keeps data and explains phase 2B', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('Verileri Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verileri Sil'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bu cihazdaki yerel verileri silmek istediğinizden emin misiniz?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    expect(find.text('Verileri Sil'), findsOneWidget);
    expect(
      find.text('Silinecek yerel veri henüz yok. Yerel veri katmanı Faz 2B.'),
      findsOneWidget,
    );
  });

  testWidgets('interest row navigates to the existing interests route', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);

    await tester.tap(find.text('İlgi Alanları'));
    await tester.pumpAndSettle();

    expect(find.text('Akışını şekillendir'), findsOneWidget);
  });

  testWidgets('shows the design-fixture-only version footer', (tester) async {
    await pumpSettingsScreen(tester);

    const footer = 'Uygulama Sürümü: [DESIGN_FIXTURE_ONLY]';
    await tester.ensureVisible(find.text(footer));
    await tester.pumpAndSettle();

    expect(find.text(footer), findsOneWidget);
    final footerText = tester.widget<Text>(find.text(footer));
    expect(footerText.style?.fontFamily, AppTypography.technical.fontFamily);
  });
}
