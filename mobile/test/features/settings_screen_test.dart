import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_harness.dart';
import 'package:tecos/design_system/tokens/app_palette.dart';
import 'package:tecos/app/app_version.dart';
import 'package:tecos/app/router.dart';
import 'package:tecos/data/app_preferences.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/design_system/tokens/app_tokens.dart';

import '../support/test_overrides.dart';

Future<void> pumpSettingsScreen(WidgetTester tester) async {
  final router = createRouter(initialLocation: '/settings');
  addTearDown(router.dispose);

  // Ayarlar'dan İlgi Alanları'na geçilebildiği için bu test de veri
  // katmanına ulaşır; override'sız bir scope gerçek sqflite'ı arar.
  await tester.pumpWidget(memoryDataScope(testRouterApp(router)));
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
    expect(deleteLabel.style?.color, AppPalette.dark.critical);

    final deleteIcon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
    expect(deleteIcon.color, AppPalette.dark.critical);
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

  /// Önceden bu satır "Liste ekranı onaylı tasarımda henüz yok." diyen bir
  /// SnackBar açıyordu ve test **o mesajı** kilitliyordu — yani ekranın
  /// olmadığını doğruluyordu. Ekran artık var.
  testWidgets('the reading-history row opens the history screen', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('Okuma Geçmişi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Okuma Geçmişi'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('read-history-empty')), findsOneWidget);
  });

  testWidgets('interest row navigates to the existing interests route', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);

    await tester.tap(find.text('İlgi Alanları'));
    await tester.pumpAndSettle();

    expect(find.text('Akışını şekillendir'), findsOneWidget);
  });

  testWidgets('the about row opens a real screen', (tester) async {
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('tecOS Hakkında'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tecOS Hakkında'));
    await tester.pumpAndSettle();

    expect(find.text('Hesap yok'), findsOneWidget);
    expect(find.text('Veriler bu cihazda'), findsOneWidget);
  });

  testWidgets('the source-policy row opens a real screen', (tester) async {
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('Kaynak Politikası'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaynak Politikası'));
    await tester.pumpAndSettle();

    expect(find.text('İçerik nereden geliyor?'), findsOneWidget);
  });

  testWidgets('the licences row opens Flutter\'s licence page', (tester) async {
    await pumpSettingsScreen(tester);

    await tester.ensureVisible(find.text('Lisanslar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lisanslar'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  /// Sürüm satırı `[DESIGN_FIXTURE_ONLY]` yer tutucusunu kullanıcıya olduğu
  /// gibi gösteriyordu ve test bunu **kilitliyordu**. Artık gerçek sürüm
  /// yazıyor; biçim (monospace `technical`) onaylı tasarımdaki gibi kalıyor.
  testWidgets('shows the real application version', (tester) async {
    await pumpSettingsScreen(tester);

    const footer = 'Uygulama Sürümü: $appVersionLabel';
    await tester.ensureVisible(find.text(footer));
    await tester.pumpAndSettle();

    expect(find.text(footer), findsOneWidget);
    expect(find.textContaining('DESIGN_FIXTURE_ONLY'), findsNothing);
    final footerText = tester.widget<Text>(find.text(footer));
    expect(footerText.style?.fontFamily, AppTypography.technical.fontFamily);
  });

  /// Uygulanmamış satırlar **dokunulabilir görünmemeli**.
  ///
  /// Bir SnackBar'ın "sonraki fazda uygulanacak" demesi kusuru kabul etmekti,
  /// gidermek değil: satırda hâlâ `>` oku duruyor, yani bir ekran vaat
  /// ediyordu. Test hem vaadin kalktığını hem de eski özrün geri gelmediğini
  /// ölçer.
  testWidgets('upcoming rows promise nothing and apologise for nothing', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);

    // 'Tema' bu listede **değil**: 2026-08-11'de gerçek bir kontrole
    // dönüştü (açık · koyu · sistem). Ölçümü ayrı testte.
    for (final title in [
      'Dil',
      'İçerik Tercihleri',
      'Asistan Konuşmaları',
      'Verileri Dışa Aktar',
    ]) {
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      expect(
        find.text('Bu ekran sonraki fazda uygulanacak.'),
        findsNothing,
        reason: '$title satırı hâlâ "sonraki fazda" özrü gösteriyor',
      );
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: '$title satırı dokununca bildirim gösteriyor',
      );
    }

    expect(find.text('Yakında'), findsNWidgets(4));
  });

  /// Tema seçimi **gerçekten çalışıyor** mu?
  ///
  /// Üç seçeneğin çizilmesi yetmez: bu ekran uzun süre "dokunulunca hiçbir
  /// şey yapmayan satır" kusurunun merkeziydi. Ölçülen şey, seçimin diske
  /// yazılması — uygulama kapanıp açıldığında geri gelmesini sağlayan tek şey.
  group('tema seçimi', () {
    testWidgets('üç seçenek çizilir ve varsayılan sistemdir', (tester) async {
      await pumpSettingsScreen(tester);

      await tester.ensureVisible(find.text('Tema'));
      await tester.pumpAndSettle();

      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Açık'), findsOneWidget);
      expect(find.text('Koyu'), findsOneWidget);

      final button = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(button.selected, {ThemeMode.system});
    });

    testWidgets('seçim diske yazılır', (tester) async {
      await pumpSettingsScreen(tester);

      await tester.ensureVisible(find.text('Tema'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Açık'));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      expect(
        AppPreferences(preferences).themeMode,
        ThemeMode.light,
        reason: 'seçim yalnız ekranda kaldı, diske yazılmadı',
      );

      await tester.tap(find.text('Koyu'));
      await tester.pumpAndSettle();

      final after = await SharedPreferences.getInstance();
      expect(AppPreferences(after).themeMode, ThemeMode.dark);
    });
  });

  /// Etkin satırlar okunu korumalı: "Yakında" düzeltmesi, gerçekten çalışan
  /// satırların da yönlendirme işaretini silseydi karşı yönde bir kusur olurdu.
  testWidgets('working rows keep their chevron', (tester) async {
    await pumpSettingsScreen(tester);

    // İlgi Alanları, Kaydedilen İçerikler, Okuma Geçmişi, Verileri Sil,
    // Hakkında, Kaynak Politikası, Lisanslar.
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(7));
  });

  /// Dil satırı **veriden** şekil alıyor: seçici, yayın birden fazla dil
  /// sunduğunda belirir. `FEED_URL` derleme sabiti olduğu için bu davranışın
  /// yayından önce yerinde olması şart — sonradan eklenirse, güncellemeyen
  /// kullanıcı yeni dilleri hiç göremez.
  group('dil satırı', () {
    Future<void> pumpWith(WidgetTester tester, FakeFeedRepository feed) async {
      final router = createRouter(initialLocation: '/settings');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        memoryDataScope(testRouterApp(router), feedRepository: feed),
      );
      await tester.pumpAndSettle();
    }

    /// Bugünkü durum. Tek seçenek gösteren bir liste açmak, kullanıcıya seçim
    /// yaptığını sandıran boş bir jest olurdu.
    testWidgets('tek dil sunulduğunda satır dokunulabilir değil', (
      tester,
    ) async {
      await pumpWith(tester, FakeFeedRepository(testFeedItems()));

      expect(find.text('Dil'), findsOneWidget);
      expect(find.text('Türkçe'), findsOneWidget);

      await tester.tap(find.text('Dil'));
      await tester.pumpAndSettle();
      expect(find.text('İçerik dili'), findsNothing);
    });

    testWidgets('iki dil sunulduğunda seçici açılır', (tester) async {
      await pumpWith(
        tester,
        FakeFeedRepository(
          testFeedItems(),
          availableLanguages: const [
            FeedLanguage(code: 'tr', url: 'feed.json'),
            FeedLanguage(code: 'en', url: 'feed.en.json'),
          ],
        ),
      );

      // Seçim yokken gösterilen şey **sonuç**: kullanıcı hangi dili
      // okuduğunu görmeli, hangi kuralın onu seçtiğini değil.
      expect(find.text('Türkçe · otomatik'), findsOneWidget);

      await tester.tap(find.text('Dil'));
      await tester.pumpAndSettle();

      expect(find.text('İçerik dili'), findsOneWidget);
      expect(find.text('Cihazın dili'), findsOneWidget);
      // Dil adları **kendi dillerinde**: İngilizce arayan biri "İngilizce"
      // yazısını okuyamıyor olabilir.
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('seçim satıra yansır ve diske yazılır', (tester) async {
      await pumpWith(
        tester,
        FakeFeedRepository(
          testFeedItems(),
          availableLanguages: const [
            FeedLanguage(code: 'tr', url: 'feed.json'),
            FeedLanguage(code: 'en', url: 'feed.en.json'),
          ],
        ),
      );

      await tester.tap(find.text('Dil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget, reason: 'satırdaki değer');
      expect(find.text('Türkçe · otomatik'), findsNothing);

      final preferences = AppPreferences(await SharedPreferences.getInstance());
      expect(preferences.feedLanguage, 'en');
    });
  });
}
