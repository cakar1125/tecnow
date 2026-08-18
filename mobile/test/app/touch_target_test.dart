import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import '../test_harness.dart';
import 'package:tecos/app/router.dart';
import 'package:tecos/data/interests/interest_taxonomy.dart';
import 'package:tecos/design_system/tokens/app_tokens.dart';

import '../support/test_overrides.dart';

/// Dokunma alanı kapısı: her ekran, her ham dokunulabilir kontrol.
///
/// `QUALITY_GATES.md` "Minimum 44×44 dokunma alanı" diyor. Kural uzun süredir
/// yazılıydı ve **hiçbir yerde ölçülmüyordu**. İlk ölçümde (2026-07-28) Ana
/// Sayfa'nın dört sekmesi 39 dp çıktı: 44'lük bir kutunun dört köşesi de
/// ıskalıyordu, yani uygulamanın en çok kullanılan kontrolü kuralı
/// sağlamıyordu.
///
/// **Widget'ın boyutunu ölçmez.** İlk deneme onu ölçtü ve yanlış cevap verdi:
/// Material'in `FilterChip`/`IconButton` bileşenleri görünen kutunun dışına
/// taşan bir dokunma alanı ekliyor, yani 38 dp'lik bir çip aslında kuralı
/// sağlıyor. Kapı gerçek soruyu soruyor: **o noktaya dokunulursa kontrol
/// dokunuşu alıyor mu?**
///
/// Yalnız 1.0 yazı ölçeğinde ölçülür ve bu yeterlidir: ölçek büyüdükçe
/// kontroller yalnız **büyür**. En kötü durum en küçük ölçektir.
void main() {
  setUpAll(loadAppFonts);

  const width = 360.0;
  const height = 844.0;

  const routes = <String>[
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
    '/icerik/0000000000000001',
    '/icerik/0000000000000002',
    '/icerik/0000000000000003',
    '/hakkinda',
    '/kaynak-politikasi',
    '/okuma-gecmisi',
  ];

  /// Elle yazılan liste unutulur; bu yüzden eksiksizliği yönlendiriciye
  /// sorduruluyor. Aynı ders taşma kapısında iki kez yaşandı.
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
      final regex = RegExp(
        '^${pattern.replaceAll(RegExp(r':[^/]+'), '[^/]+')}\$',
      );
      expect(
        routes.any(regex.hasMatch),
        isTrue,
        reason:
            '$pattern rotası dokunma alanı matrisinde yok — ekranın '
            'kontrolleri hiç ölçülmüyor.',
      );
    }
  });

  for (final route in routes) {
    testWidgets('$route · dokunma alanları 44 dp', (tester) async {
      tester.view.physicalSize = const Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = createRouter(initialLocation: route);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        memoryDataScope(
          testRouterApp(router),
          // Seçim yokken Ana Sayfa'nın sekme şeridi iki sekmede kalıyor ve
          // İlgi Alanları'ndaki sıralama listesi hiç çizilmiyor — yani
          // dolu hâlleri ölçüsüz kalırdı. Kapı ekranı kullanıldığı gibi
          // görmeli.
          interests: [for (final interest in interestTaxonomy) interest.id],
        ),
      );
      await tester.pumpAndSettle();

      final tooSmall = <String>[];
      final targets = find
          .byWidgetPredicate(
            (widget) =>
                (widget is InkWell && widget.onTap != null) ||
                (widget is InkResponse && widget.onTap != null),
          )
          .evaluate();

      for (final element in targets) {
        final box = element.renderObject;
        if (box is! RenderBox || !box.hasSize || box.size.isEmpty) continue;

        final size = box.size;
        // Kendi kutusu zaten 44x44'ü kapsıyorsa kontrol yeterlidir. Bu
        // durumda köşe denemesi kaydırma kırpmasını ölçer, kontrolü değil:
        // ilk koşuda `Verileri Sil` (328x64) yalnız listenin altında
        // kaldığı için kusurlu görünmüştü.
        if (size.width >= AppTouchTarget.minimum &&
            size.height >= AppTouchTarget.minimum) {
          continue;
        }

        final rect = box.localToGlobal(Offset.zero) & size;
        final probe = Rect.fromCenter(
          center: rect.center,
          width: AppTouchTarget.minimum,
          height: AppTouchTarget.minimum,
        );
        // Ekran kenarında kısmen görünen kontrol ölçülmez.
        const screen = Rect.fromLTWH(0, 0, width, height);
        if (!screen.contains(probe.topLeft) ||
            !screen.contains(probe.bottomRight)) {
          continue;
        }

        // Köşeler 0.5 dp içeriden denenir: tam köşe noktası iki kutunun
        // sınırına düşer ve ölçümü yuvarlama hatasına açık bırakır.
        const half = AppTouchTarget.minimum / 2 - 0.5;
        final missed =
            <Offset>[
              for (final dx in const [-half, half])
                for (final dy in const [-half, half]) Offset(dx, dy),
            ].where((corner) {
              final result = tester.hitTestOnBinding(rect.center + corner);
              return !result.path.any((entry) => entry.target == box);
            }).length;

        if (missed == 0) continue;

        final labels = <String>[];
        void visit(Element child) {
          final widget = child.widget;
          if (widget is Text && widget.data != null) labels.add(widget.data!);
          if (widget is Icon) labels.add('ikon:${widget.icon?.codePoint}');
          child.visitChildren(visit);
        }

        element.visitChildren(visit);

        tooSmall.add(
          '${labels.isEmpty ? "(metinsiz)" : labels.take(2).join(" / ")} — '
          '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)} dp, '
          '44 dp kutunun $missed köşesi ıskalıyor',
        );
      }

      expect(
        tooSmall,
        isEmpty,
        reason:
            '$route ekranında dokunma alanı 44 dp altında kalan kontroller '
            'var:\n  ${tooSmall.join("\n  ")}\n'
            'Çizilen kutuyu büyütmeden düzeltmek için kontrolü '
            '`ConstrainedBox(minHeight: AppTouchTarget.minimum)` içine alın; '
            'bkz. `_FeedTabButton`.',
      );
    });
  }
}
