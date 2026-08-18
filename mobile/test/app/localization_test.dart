import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/app/app.dart';
import 'package:tecos/data/providers.dart';
import 'package:tecos/l10n/app_localizations.dart';

/// Dil kapısı: uygulamanın **kendi** metinleri ve Flutter'ın hazır ekranları.
///
/// Bu dosya "uygulama tek dil bildiriyor"u ölçüyordu. 17 Ağustos 2026'da ikinci
/// dil geldi, yani o beklenti doğru bir gerçeği değil **eski** bir gerçeği
/// tarif ediyordu. Gevşetilmedi: yerine gelenler daha fazlasını ölçüyor.
///
/// İki girdi ayrı ayrı veriliyor ve ikisi de gerçek yoldan:
/// - **cihazın dili** `deviceLanguageProvider` override'ıyla. Sağlayıcı zaten
///   testler için ayrılmıştı; `PlatformDispatcher.instance` global olduğu için
///   `tester.platformDispatcher` ona ulaşmıyor.
/// - **kullanıcının seçimi** `restore()` ile — uygulamanın açılışta diskteki
///   tercihi geri yüklerken kullandığı metot. Sahte bir notifier, üretimde hiç
///   çalışmayan bir kod yolunu ölçerdi.
Future<MaterialApp> _pumpApp(
  WidgetTester tester, {
  String? device = 'tr',
  String? preferred,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [deviceLanguageProvider.overrideWithValue(device)],
      child: const TecOsApp(),
    ),
  );
  await tester.pump();

  if (preferred != null) {
    ProviderScope.containerOf(
      tester.element(find.byType(TecOsApp)),
    ).read(feedLanguageProvider.notifier).restore(preferred);
    await tester.pump();
  }

  return tester.widget<MaterialApp>(find.byType(MaterialApp));
}

L10n _l10n(WidgetTester tester) =>
    L10n.of(tester.element(find.byType(Navigator).first));

MaterialLocalizations _material(WidgetTester tester) =>
    MaterialLocalizations.of(tester.element(find.byType(Navigator).first));

void main() {
  /// Arayüzün tamamı Türkçe yazılmıştı ama `localizationsDelegates`
  /// verilmediği için Flutter'ın hazır ekranları İngilizce kalıyordu. Cihazda
  /// görüldü (2026-07-28): Ayarlar → Lisanslar başlığı **"Licenses"**
  /// yazıyordu, Türkçe bir uygulamanın ortasında.
  ///
  /// Test delege listesini saymıyor, **sonuca** bakıyor: delege eklenip
  /// `locale` unutulduğunda liste sayımı yine geçerdi.
  testWidgets('Flutter\'ın hazır metinleri de uygulamanın dilini izler', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(_material(tester).licensesPageTitle, 'Lisanslar');
    expect(_material(tester).closeButtonTooltip, isNot('Close'));
  });

  testWidgets('uygulamanın kendi metinleri delege üzerinden geliyor', (
    tester,
  ) async {
    await _pumpApp(tester);

    // `L10n.of` delege yoksa **fırlatır** (`nullable-getter: false`), yani bu
    // beklenti delegenin gerçekten bağlı olduğunu ölçüyor.
    expect(
      _l10n(tester).feedSyncBundled,
      'İçerik uygulamayla birlikte geliyor',
    );
  });

  testWidgets('desteklenen diller bildiriliyor', (tester) async {
    final app = await _pumpApp(tester);

    expect(app.supportedLocales, containsAll(supportedUiLocales));
    expect(app.locale, isNotNull, reason: 'dil cihaza bırakılmıyor');
  });

  /// Seçim yokken cihazın dili geçerli. Geçerli olmazsa İngilizce bir telefon
  /// açan kullanıcı, hiçbir şey seçmediği hâlde Türkçe bir uygulama görür.
  testWidgets('seçim yokken cihazın dili uygulanır', (tester) async {
    final app = await _pumpApp(tester, device: 'en');

    expect(app.locale, const Locale('en'));
    expect(_l10n(tester).feedSyncBundled, 'Content ships with the app');
  });

  /// Kullanıcının seçimi cihazı **ezmeli**. Ezmezse ayarlardaki dil satırı
  /// hiçbir şey yapmıyor demektir ve ekranda her şey doğru görünür.
  testWidgets('kullanıcının seçimi cihazın dilini ezer', (tester) async {
    final app = await _pumpApp(tester, device: 'en', preferred: 'tr');

    expect(app.locale, const Locale('tr'));
    expect(
      _l10n(tester).feedSyncBundled,
      'İçerik uygulamayla birlikte geliyor',
    );
    expect(_material(tester).licensesPageTitle, 'Lisanslar');
  });

  /// Arayüzün çevirisi olmayan bir dil kırılma sebebi değil. İçerik listesi
  /// sunucudan geliyor ve arayüz listesinden büyük olabilir: sunucu Almanca
  /// yayın eklerse içerik Almanca gelir, arayüz gelmez — ve gelmemeli, çünkü
  /// eksik çeviri yanlış çeviriden iyidir.
  testWidgets('desteklenmeyen dil varsayılana düşer', (tester) async {
    expect((await _pumpApp(tester, device: 'de')).locale, const Locale('tr'));
    expect(
      (await _pumpApp(tester, device: 'en', preferred: 'de')).locale,
      const Locale('tr'),
    );
  });

  /// Cihaz dili hiç bildirilmediğinde (gömülü ortamlar, bazı test koşucuları)
  /// uygulama düşmemeli.
  testWidgets('cihaz dili bilinmiyorsa varsayılan kullanılır', (tester) async {
    expect((await _pumpApp(tester, device: null)).locale, const Locale('tr'));
  });
}
