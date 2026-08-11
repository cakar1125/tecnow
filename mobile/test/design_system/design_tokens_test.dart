import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/design_system/tokens/app_palette.dart';
import 'package:tecos/design_system/tokens/app_tokens.dart';

void main() {
  /// Onaylı tasarım sisteminin sayısal kilidi.
  ///
  /// `aiAccent` 2026-08-11'de #A855F7'den #B37AF8'e alındı. Sebep estetik
  /// değil ölçüm: eski mor `surfaceHigh` (#181D25) üstünde **4.28:1**
  /// veriyordu ve WCAG AA eşiği 4.5. "tecOS ÖZETİ" rozeti ile etiket
  /// kutuları o zemini kullanıyor. Yeni değer aynı zeminde 5.68:1.
  /// Gerekçe ve ölçüm: `palette_contrast_test.dart`.
  test('design token values match the approved master system', () {
    expect(AppPalette.dark.background.toARGB32(), 0xFF0A0C10);
    expect(AppPalette.dark.primary.toARGB32(), 0xFF00F0FF);
    expect(AppPalette.dark.aiAccent.toARGB32(), 0xFFB37AF8);
    expect(AppSpacing.lg, 16);
    expect(AppRadius.card.x, 12);
    expect(AppBreakpoints.reference, 390);
    expect(AppDurations.normal.inMilliseconds, 200);
  });

  /// Marka rengi **iki temada da** kilitli.
  ///
  /// Açık temanın turkuazı camgöbeğinden türetildi ama beyaz zeminde
  /// okunabilmesi için koyulaştırıldı (#00F0FF beyazda 1.32:1). İkisinin de
  /// burada yazılı olması, birinin sessizce diğerine eşitlenmesini engeller.
  test('marka rengi her iki temada da kilitli', () {
    expect(AppPalette.dark.primary.toARGB32(), 0xFF00F0FF);
    expect(AppPalette.light.primary.toARGB32(), 0xFF0C6A83);
  });
}
