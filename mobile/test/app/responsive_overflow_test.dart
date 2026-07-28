import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:teknoakis/app/router.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';

import '../support/test_overrides.dart';

/// Uygulamanın taşma kapısı: her ekran, her genişlikte, her yazı ölçeğinde.
///
/// Bu dosya `shell_responsive_test.dart`'ın yerini aldı. Eski kapı üç yerde
/// birden kördü ve üçü de aynı gün ölçüldü (2026-07-28):
///
/// 1. **Yanlış yazı tipi.** Varsayılan test fontunun glif metrikleri gerçek
///    fonttan farklı; bazı ölçeklerde taşmayı olduğundan fazla, bazılarında
///    hiç göstermiyor. `loadAppFonts()` artık zorunlu.
/// 2. **Tek yazı ölçeği.** Yalnız 1.0 ölçülüyordu. Bulunan gerçek taşma
///    1.6'da oluşuyordu, yani kapının hiç bakmadığı yerde.
/// 3. **Yalnız kabuk sekmeleri.** Detay ekranı, onboarding, ilgi alanları ve
///    Ayarlar'dan açılan sayfalar kabuğun **dışında** rota; kapı onlara hiç
///    bakmıyordu. Bulunan taşma da tam oradaydı.
///
/// Koşum düzeninin gerçekten taşma yakaladığı doğrulandı: `_Fact` düzeltmesi
/// geçici olarak geri alındığında bu dosya kırmızıya döndü ve **bilinen**
/// koşulu (360 dp / 1.6) tek tek işaretledi.
///
/// Genişlik tek başına belirleyici **değil**: aynı deneme 430 dp / 2.0'da da
/// taşma buldu, 360 dp / 2.0'da bulmadı. Dar ekranda metin sarıp sığıyor,
/// geniş ekranda tek satırda kalıp taşıyor. Bu yüzden matris çarpım olarak
/// kuruluyor, "en dar + en büyük" kestirmesiyle değil.
void main() {
  setUpAll(loadAppFonts);

  /// `QUALITY_GATES.md`'deki kırılım noktaları.
  const widths = <double>[360, 390, 430];

  /// Android'in sunduğu yazı ölçekleri. 2.0 uydurma bir uç değil: Android 14
  /// erişilebilirlik ayarlarında ulaşılabilen gerçek bir değer.
  const scales = <double>[1.0, 1.3, 1.6, 2.0];

  /// Uygulamanın **bütün** rotaları. Kabuk sekmeleri artık listenin yalnız
  /// bir bölümü.
  const routes = <String>[
    // Listeye ilk koşuda **bu test tarafından** eklendi: elle yazılan matris
    // `/splash`'i atlamıştı ve açılış ekranı hiç ölçülmüyordu.
    '/splash',
    '/home',
    '/explore',
    '/assistant',
    '/saved',
    '/settings',
    '/onboarding/0',
    '/onboarding/1',
    '/onboarding/2',
    '/interests',
    // Üç farklı tür: başlık, vurgu ve olgu satırları türden türetiliyor.
    '/icerik/0000000000000001',
    '/icerik/0000000000000002',
    '/icerik/0000000000000003',
    '/hakkinda',
    '/kaynak-politikasi',
    '/okuma-gecmisi',
  ];

  /// Listenin **eksiksiz** olduğunu yönlendiricinin kendisine sordurur.
  ///
  /// Yukarıdaki liste elle yazılı ve elle yazılan her liste unutulur: yeni bir
  /// rota eklenip buraya yazılmazsa ekran sessizce ölçüsüz kalırdı. Tam da bu
  /// oturumda iki kez yaşandı — eski kapı kabuk dışındaki rotalara hiç
  /// bakmıyordu ve 28 Temmuz'da eklenen üç ekranın hiç taşma kapısı yoktu.
  ///
  /// Bu test unutmayı **gürültülü** hâle getiriyor.
  test('matris yönlendiricideki her rotayı kapsıyor', () {
    final router = createRouter();
    addTearDown(router.dispose);

    final patterns = <String>{};
    void collect(List<RouteBase> children) {
      for (final route in children) {
        if (route is GoRoute) patterns.add(route.path);
        collect(route.routes);
      }
    }

    collect(router.configuration.routes);

    for (final pattern in patterns) {
      // `/onboarding/:step` gibi parametreli yollar için desen eşleşmesi.
      final regex = RegExp(
        '^${pattern.replaceAll(RegExp(r':[^/]+'), '[^/]+')}\$',
      );
      expect(
        routes.any(regex.hasMatch),
        isTrue,
        reason:
            '$pattern rotası taşma matrisinde yok — ekran hiç ölçülmüyor. '
            'Yukarıdaki `routes` listesine örnek bir yol ekleyin.',
      );
    }
  });

  for (final width in widths) {
    for (final route in routes) {
      for (final scale in scales) {
        testWidgets('$route · ${width.toInt()} dp · ${scale}x', (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final router = createRouter(initialLocation: route);
          addTearDown(router.dispose);

          await tester.pumpWidget(
            memoryDataScope(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: MaterialApp.router(
                  theme: AppTheme.dark,
                  routerConfig: router,
                ),
              ),
              // Geçmiş **dolu** ölçülüyor: boş durum tek satırlık bir metin,
              // taşma riski satırların kendisinde.
              readHistory: _seededHistory(),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

InMemoryReadHistoryRepository _seededHistory() {
  final history = InMemoryReadHistoryRepository();
  history.records.addAll(const [
    (itemId: '0000000000000001', kind: 'repository'),
    (itemId: '0000000000000003', kind: 'announcement'),
    // Çözülemeyen satır da ölçülüyor: farklı metin, farklı uzunluk.
    (itemId: 'artik-akista-olmayan', kind: 'skill'),
  ]);
  return history;
}
