import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:teknoakis/design_system/components/app_components.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/design_system/tokens/app_tokens.dart';

/// `DECISION_LOG.md` D-005 ve `CLAUDE.md` alt navigasyon etiketlerini sabitler;
/// bu adlar kısaltılarak "düzeltilemez".
const _navLabels = <String>[
  'Ana Sayfa',
  'Keşfet',
  'Asistan',
  'Kaydedilenler',
  'Ayarlar',
];

/// Etiketler gerçek Inter ile ölçülmelidir: varsayılan test yazı tipinin her
/// glifi kare olduğundan ölçüm gerçeği yansıtmaz.
void main() {
  setUpAll(loadAppFonts);

  group('AppBottomNavigation etiketleri', () {
    /// Fiziksel cihaz kabulünde (OnePlus 8 Pro, 360 dp) "Kaydedilenler"
    /// kelimenin ortasından ikinci satıra taşıyordu: 12sp ile 79.8 dp gerekiyor,
    /// beş bölmeli navigasyonda 360 dp'de bir bölme 72 dp.
    /// `shell_responsive_test.dart` bunu göremez, çünkü sarmalama bir taşma
    /// istisnası üretmez; bu yüzden yükseklik doğrudan ölçülüyor.
    for (final width in <double>[360, 390, 430]) {
      testWidgets('${width.toInt()} px: her etiket tek satırda', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: AppScaffold(
              currentIndex: 0,
              onDestinationSelected: (_) {},
              child: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 'Keşfet' her genişlikte tek satıra sığan en kısa etiket: referans.
        final singleLineHeight = tester
            .renderObject<RenderParagraph>(find.text('Keşfet'))
            .size
            .height;

        for (final label in _navLabels) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(
            paragraph.size.height,
            singleLineHeight,
            reason:
                '"$label" ${width.toInt()} px ekranda tek satırda kalmalı; '
                'ölçülen yükseklik ${paragraph.size.height}, '
                'tek satır $singleLineHeight.',
          );
        }
      });
    }

    testWidgets('etiket stili navLabel token\'ından gelir', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: AppScaffold(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final style = tester
          .renderObject<RenderParagraph>(find.text('Kaydedilenler'))
          .text
          .style!;
      expect(style.fontSize, AppTypography.navLabel.fontSize);
      expect(style.letterSpacing, AppTypography.navLabel.letterSpacing);
    });
  });

  group('SnackBar teması', () {
    /// Cihaz kabulünde SnackBar koyu temanın üstünde beyaz bir bant olarak
    /// çıkıyordu: `AppTheme.dark` içinde `snackBarTheme` tanımlı değildi ve
    /// Material varsayılanı devreye giriyordu.
    testWidgets('koyu yüzey token\'ı kullanır', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('örnek bildirim'))),
                child: const Text('göster'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('göster'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, AppColors.surfaceHigh);

      final text = tester.widget<Text>(find.text('örnek bildirim'));
      expect(
        text.style?.color ?? AppTypography.body.color,
        AppColors.textPrimary,
      );
    });
  });
}
