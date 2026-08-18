import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../design_system/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

class TecOsApp extends ConsumerWidget {
  const TecOsApp({super.key});

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
      // Dil **açıkça** veriliyor, cihaza bırakılmıyor: kullanıcı ayarlardan
      // bir dil seçtiyse cihaz ne derse desin o geçerli olmalı.
      locale: ref.watch(localeProvider),
      supportedLocales: supportedUiLocales,
      // `L10n` bizim dizelerimiz; `Global*` delegeleri Flutter'ın **kendi**
      // hazır ekranlarını (lisans sayfası, metin seçim menüsü, tarih seçici)
      // besliyor. İkincisi olmadan cihazda görülmüştü (2026-07-28):
      // Ayarlar → Lisanslar başlığı Türkçe bir uygulamanın ortasında
      // **"Licenses"** yazıyordu.
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
