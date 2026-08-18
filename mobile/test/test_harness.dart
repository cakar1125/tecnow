import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tecos/data/providers.dart';
import 'package:tecos/design_system/theme/app_theme.dart';
import 'package:tecos/l10n/app_localizations.dart';

/// Testlerin kullandığı dil delegeleri — **üretimdekiyle aynı liste**.
///
/// Tek bir sabit olarak duruyor çünkü kopyalandığı her yerde ayrışabilir:
/// golden testleri `golden_toolkit`'in kendi sarmalayıcısını kullanıyor ve
/// listeyi oraya elle yazmak, iki listenin bir gün farklı olmasını
/// zamanlamaya bırakmak olurdu.
const testLocalizationDelegates = <LocalizationsDelegate<Object?>>[
  L10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Uygulama kabuğu olmadan tek bir widget'ı gerçek tema altında render eder.
///
/// `ProviderScope` **dışarıda** bırakıldı: veri katmanına bağlı ekranlar
/// override'lı bir scope ister (`support/test_overrides.dart`), bağlı olmayanlar
/// [testHarness] ile sade scope kullanır.
///
/// Delegeler **gerçek uygulamayla aynı**. Testin kendi kurduğu kabuk üretimden
/// ayrışırsa test, üretimde olmayan bir dünyayı ölçer: burada delege eksik
/// olsaydı `context.l10n` çalışma anında düşer ve kusur ancak cihazda
/// görünürdü.
Widget testApp(Widget child, {double textScale = 1, Locale? locale}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: locale ?? const Locale('tr'),
      supportedLocales: supportedUiLocales,
      localizationsDelegates: testLocalizationDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: child,
    );

/// Router'ı kendisi kuran testler için kabuk.
///
/// Ayrı bir yardımcı olması şart: delege listesi kopyalandığı her yerde
/// birbirinden ayrışabilir ve ayrıştığı gün ölçüm üretimden farklı bir
/// dünyayı ölçmeye başlar. Tek kaynak, tek doğru.
Widget testRouterApp(
  RouterConfig<Object> routerConfig, {
  double textScale = 1,
  Locale? locale,
}) => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.dark,
  locale: locale ?? const Locale('tr'),
  supportedLocales: supportedUiLocales,
  localizationsDelegates: testLocalizationDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  routerConfig: routerConfig,
);

Widget testHarness(Widget child, {double textScale = 1, Locale? locale}) =>
    ProviderScope(
      child: testApp(child, textScale: textScale, locale: locale),
    );
