import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../design_system/theme/app_theme.dart';
import 'router.dart';

class TeknoakisApp extends StatelessWidget {
  const TeknoakisApp({super.key});

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
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TeknoAkış',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
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
