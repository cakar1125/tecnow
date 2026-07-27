import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/data/app_preferences.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/design_system/tokens/app_tokens.dart';

import '../support/test_overrides.dart';

Future<void> pumpSettingsScreen(WidgetTester tester) async {
  final router = createRouter(initialLocation: '/settings');
  addTearDown(router.dispose);

  // Ayarlar'dan İlgi Alanları'na geçilebildiği için bu test de veri
  // katmanına ulaşır; override'sız bir scope gerçek sqflite'ı arar.
  await tester.pumpWidget(
    memoryDataScope(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
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

  testWidgets('local data rows report real record counts', (tester) async {
    await pumpSettingsScreen(tester);

    // Tohumlanmış beş kayıt, henüz okunmuş içerik yok.
    expect(find.text('5 kayıt'), findsOneWidget);
    expect(find.text('0 kayıt'), findsNWidgets(2));
  });

  testWidgets('cancelling the delete dialog keeps the data', (tester) async {
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('Verileri Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verileri Sil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(find.text('5 kayıt'), findsOneWidget);
  });

  testWidgets('confirming the delete dialog really empties local data', (
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

    expect(find.text('5 kayıt'), findsNothing);
    expect(find.text('0 kayıt'), findsNWidgets(3));
    expect(find.textContaining('Yerel veriler silindi'), findsOneWidget);
  });

  /// Silme, onboarding bayrağını da sıfırlamalı: ilgi alanları gittiği için
  /// uygulama boş ama "kurulmuş" bir durumda kalmamalı.
  testWidgets('deleting local data resets the onboarding flag', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.onboardingCompletedKey: true,
    });
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('Verileri Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verileri Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AppPreferences.onboardingCompletedKey), isNull);
  });

  /// Okuma geçmişi yazılıyor ama liste ekranı onaylı tasarımda yok; mesaj bu
  /// gerçeği söylemeli, "sonraki fazda" diye geçiştirmemeli.
  testWidgets('the reading-history row states what actually exists', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('Okuma Geçmişi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Okuma Geçmişi'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Okuma geçmişi kaydediliyor. Liste ekranı onaylı tasarımda henüz yok.',
      ),
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
