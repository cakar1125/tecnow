import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/app/app.dart';

/// Flutter'ın **kendi** ekranları da Türkçe olmalı.
///
/// Arayüzün tamamı Türkçe yazılmıştı ama `localizationsDelegates` verilmediği
/// için hazır Material ekranları İngilizce kalıyordu. Cihazda görüldü
/// (2026-07-28): Ayarlar → Lisanslar başlığı **"Licenses"** yazıyordu.
///
/// Test dile değil **sonuca** bakıyor: delege listesini saymak, delege
/// eklenip `locale` unutulduğunda yine geçerdi.
void main() {
  testWidgets('Material\'in hazır metinleri Türkçe geliyor', (tester) async {
    late MaterialLocalizations localizations;

    await tester.pumpWidget(const TecNowApp());
    await tester.pump();

    final context = tester.element(find.byType(Navigator).first);
    localizations = MaterialLocalizations.of(context);

    expect(localizations.licensesPageTitle, 'Lisanslar');
    expect(localizations.closeButtonTooltip, isNot('Close'));
  });

  testWidgets('uygulama tek dil bildiriyor', (tester) async {
    await tester.pumpWidget(const TecNowApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('tr'));
    expect(app.supportedLocales, contains(const Locale('tr')));
  });
}
