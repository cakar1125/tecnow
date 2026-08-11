import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecos/data/app_preferences.dart';
import 'package:tecos/features/explore/explore_screen.dart';
import 'package:tecos/features/feed/feed_screen.dart';

import '../support/test_overrides.dart';

/// İçerik mağazasının **asıl işi**: Keşfet'te yapılan seçimin Ana Sayfa'yı
/// değiştirmesi.
///
/// Keşfet uzun süre kendi başına duran bir arama ekranıydı; hiçbir seçim
/// akışa dokunmuyordu. Bu dosya o bağı ölçüyor — bağ kopsa iki ekran yine
/// ayrı ayrı "çalışıyor" görünürdü ve hiçbir ekran testi kırılmazdı.
Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(memoryDataHarness(Scaffold(body: screen)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('kaynak listesi', () {
    testWidgets('her kaynak gerçek kayıt sayısıyla listelenir', (tester) async {
      await _pump(tester, const ExploreScreen());

      await tester.ensureVisible(find.byKey(const Key('store-source-GitHub')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('store-source-GitHub')), findsOneWidget);
      expect(
        find.byKey(const Key('store-source-Hugging Face')),
        findsOneWidget,
      );
      // Test feed'inde kaynak başına bir kayıt var; sayı uydurulmuyor.
      expect(find.text('1 kayıt'), findsWidgets);
    });

    testWidgets('varsayılan olarak hepsi açık', (tester) async {
      await _pump(tester, const ExploreScreen());

      await tester.ensureVisible(find.text('Kaynaklar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('/3 açık'),
        findsOneWidget,
        reason:
            'susturulanlar saklanıyor, takip edilenler değil — yeni bir '
            'kaynak eklendiğinde kendiliğinden açık olmalı',
      );
    });
  });

  group('kaynak kapatma', () {
    testWidgets('seçim diske yazılır', (tester) async {
      await _pump(tester, const ExploreScreen());

      final row = find.byKey(const Key('store-source-GitHub'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      final preferences = AppPreferences(await SharedPreferences.getInstance());
      expect(preferences.mutedSources, {'GitHub'});
    });

    testWidgets('ikinci dokunuş geri açar', (tester) async {
      await _pump(tester, const ExploreScreen());

      final row = find.byKey(const Key('store-source-GitHub'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      final preferences = AppPreferences(await SharedPreferences.getInstance());
      expect(preferences.mutedSources, isEmpty);
    });

    /// Kapatılan kaynak listeden **kaybolmaz**: göremediğin şeyi geri
    /// açamazsın.
    testWidgets('kapatılan kaynak listede kalır', (tester) async {
      await _pump(tester, const ExploreScreen());

      final row = find.byKey(const Key('store-source-GitHub'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(row, findsOneWidget);
    });
  });

  /// Bağın kendisi: Keşfet'te kapatılan kaynak Ana Sayfa'dan çıkmalı.
  testWidgets('kapatılan kaynak akıştan düşer', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.mutedSourcesKey: <String>['GitHub'],
    });
    final preferences = AppPreferences(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      memoryDataHarness(
        const Scaffold(body: FeedScreen()),
        mutedSources: preferences.mutedSources,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('ornek/depo'),
      findsNothing,
      reason: 'GitHub kapatıldı, GitHub kaydı akışta kalmamalı',
    );
    expect(
      find.text('ornek/model'),
      findsOneWidget,
      reason: 'diğer kaynaklar etkilenmemeli',
    );
  });

  testWidgets('hiç kaynak kapatılmamışken akış eksilmez', (tester) async {
    await tester.pumpWidget(
      memoryDataHarness(const Scaffold(body: FeedScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('ornek/depo'), findsOneWidget);
    expect(find.text('ornek/model'), findsOneWidget);
    expect(find.text('Bir duyuru'), findsOneWidget);
  });

  group('ilgi alanı seçimi', () {
    testWidgets('mağazadan seçilen ilgi alanı kalıcı olur', (tester) async {
      await _pump(tester, const ExploreScreen());

      final chip = find.byKey(const Key('store-interest-yapay-zeka'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.textContaining('seçili'), findsOneWidget);
    });
  });

  /// Tema seçimi gibi, kaynak tercihi de `Verileri Sil` ile gitmeli:
  /// yarım bir silme, silme değildir.
  test('reset kaynak tercihini de siler', () async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.mutedSourcesKey: <String>['GitHub'],
    });
    final preferences = AppPreferences(await SharedPreferences.getInstance());
    expect(preferences.mutedSources, {'GitHub'});

    await preferences.reset();

    expect(preferences.mutedSources, isEmpty);
  });
}
