import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../design_system/theme/app_theme.dart';
import 'router.dart';

class TecOsApp extends ConsumerWidget {
  const TecOsApp({super.key});

  /// Uygulamanın dili. Arayüzün tamamı Türkçe yazıldı ama Flutter'ın **kendi**
  /// hazır ekranları (lisans sayfası, metin seçim menüsü, tarih seçici)
  /// `MaterialLocalizations`'tan besleniyor ve delege verilmediğinde İngilizce
  /// kalıyorlardı.
  ///
  /// Cihazda görüldü (2026-07-28): Ayarlar → Lisanslar başlığı **"Licenses"**
  /// yazıyordu, Türkçe bir uygulamanın ortasında. `flutter_localizations`
  /// Türkçe çevirileri hazır getiriyor; yazılacak bir metin yok.
  static const _turkish = Locale('tr');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'tecOS',
      debugShowCheckedModeBanner: false,
      // Her iki tema da veriliyor; hangisinin çizileceğine `themeMode` karar
      // verir. `theme` açık, `darkTheme` koyu olmak **zorunda** — Flutter
      // `ThemeMode.system` durumunda cihazın parlaklığına göre bu iki
      // yuvadan seçer, adlarına göre değil.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: _turkish,
      supportedLocales: const [_turkish],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
