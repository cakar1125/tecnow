/// Kaynak adının **yazımı**.
///
/// Ad bir zamanlar büyütülüyordu ve iki büyütme kuralının ikisi de yanlıştı:
/// gerçek kaynak adlarının onu iki dilli (marka adı + Türkçe kelime), ve
/// hiçbir kural iki dilli bir dizginin tamamı için doğru olamıyor. Ölçüm ve
/// tablo `feed_items.dart` → `FeedMetaLine` başlığında.
///
/// Bu dosya kararı kilitliyor: biri "başlık gibi görünsün" diye tekrar
/// `toUpperCase()` eklerse burada kırılır.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/design_system/components/feed_items.dart';
import 'package:tecos/design_system/theme/app_theme.dart';
import 'package:tecos/ui/feed_signal.dart';

Future<void> _pump(
  WidgetTester tester,
  String sourceName, {
  FeedSignal? signal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: FeedMetaLine(sourceName: sourceName, signal: signal),
        ),
      ),
    ),
  );
}

void main() {
  /// Üretimdeki 14 kaynağın onu iki dilli. Her biri kendi yazımıyla
  /// görünmeli — hem markanın hem Türkçenin doğru olduğu tek biçim bu.
  group('kaynak adı kendi yazımıyla görünür', () {
    const names = [
      // Türkçe kelime taşıyanlar: `toUpperCase()` bunları bozardı
      // (GELIŞTIRICI, DEĞIŞIKLIKLER).
      'NVIDIA Geliştirici',
      'GitHub Değişiklikler',
      'AWS Makine Öğrenmesi',
      // Marka adları: Türkçe kural bunları bozardı
      // (VİSUAL STUDİO, DEEPMİND).
      'Visual Studio Code',
      'Google DeepMind',
      'Hugging Face',
    ];

    for (final name in names) {
      testWidgets('"$name"', (tester) async {
        await _pump(tester, name);

        expect(find.text(name), findsOneWidget);
        expect(
          find.text(name.toUpperCase()),
          findsNothing,
          reason: 'ad büyütülmemeli — iki dilli adlarda doğru kural yok',
        );
      });
    }
  });

  /// Gerekçe etiketi bizim yazdığımız metin: doğru yazılmış hâliyle duruyor
  /// ve büyük kalıyor. Satırın iki yarısını ayıran şey de bu fark.
  testWidgets('gerekçe etiketi olduğu gibi çizilir', (tester) async {
    await _pump(tester, 'GitHub', signal: FeedSignal.officialSource);

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('RESMİ KAYNAK'), findsOneWidget);
  });

  /// Gerekçe yoksa ayraç da çizilmez: boşta duran bir nokta, olmayan bir
  /// bilgiyi varmış gibi gösterir.
  testWidgets('gerekçe yokken yalnız kaynak kalır', (tester) async {
    await _pump(tester, 'GitHub');

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });
}
