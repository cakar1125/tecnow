import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/design_system/tokens/app_palette.dart';
import 'package:tecos/ui/source_brand.dart';

import '../design_system/palette_contrast_test.dart' show contrast;

/// Marka renklerinin kapısı.
///
/// `SourceBrand` ham `Color(0x…)` sabitleri taşıyor ve bu bilinçli: marka
/// rengi temanın bir rolü değil, kaynağın **verisi**. Ama sabit olmaları
/// onları denetimsiz bırakmaz — `typography_usage_test.dart` bu dosyayı
/// muaf tutuyor **çünkü** buradaki ölçüm var. Muafiyet, kapı olmadan
/// gevşetme olurdu.
///
/// Ölçüt: her marka rengi, kendi temasının en zorlu zemininde (`surfaceHigh`)
/// AA eşiğini (4.5:1) geçmeli. Tonlar zaten o eşiğe göre üretildi
/// (2026-08-11); bu test üretimi kilitliyor.
void main() {
  test('her marka rengi kendi temasında AA geçer', () {
    for (final brand in SourceBrand.all) {
      final dark = contrast(brand.onDark, AppPalette.dark.surfaceHigh);
      expect(
        dark,
        greaterThanOrEqualTo(4.5),
        reason:
            '${brand.initials} koyu tonu koyu yüzeyde '
            '${dark.toStringAsFixed(2)}:1',
      );

      final light = contrast(brand.onLight, AppPalette.light.surfaceHigh);
      expect(
        light,
        greaterThanOrEqualTo(4.5),
        reason:
            '${brand.initials} açık tonu açık yüzeyde '
            '${light.toStringAsFixed(2)}:1',
      );
    }
  });

  /// Aynı yayıncının birden çok akışı var (`GitHub`, `GitHub Blog`,
  /// `GitHub Değişiklikler`) ve üçü de aynı markayı taşımalı — yoksa akış
  /// tek bir kaynağı üç ayrı kimlikmiş gibi gösterir.
  test('aynı yayıncının akışları tek marka altında toplanır', () {
    final github = SourceBrand.of('GitHub');
    expect(SourceBrand.of('GitHub Blog').initials, github.initials);
    expect(SourceBrand.of('GitHub Değişiklikler').initials, github.initials);
    expect(SourceBrand.of('GitHub Blog').onDark, github.onDark);
  });

  /// Daha uzun önek daha kısa olandan **önce** eşleşmeli. `Google DeepMind`
  /// yalnız `Google` ile eşleşseydi DeepMind kendi kimliğini kaybederdi.
  test('daha özel önek önce eşleşir', () {
    expect(SourceBrand.of('Google DeepMind').initials, 'DM');
    expect(SourceBrand.of('Google AI').initials, 'G');
  });

  group('tanınmayan kaynak', () {
    test('iki kelimeden baş harfleri alır', () {
      expect(SourceBrand.of('Acme Robotics').initials, 'AR');
    });

    test('tek kelimeden ilk iki harfi alır', () {
      expect(SourceBrand.of('Zephyr').initials, 'ZE');
    });

    /// Tek harflik ad `substring(0, 2)` ile atardı.
    test('tek harflik ad çökertmez', () {
      expect(SourceBrand.of('X').initials, 'X');
    });

    test('boş ad çökertmez', () {
      expect(SourceBrand.of('   ').initials, '?');
    });
  });

  test('tema seçimi paletin parlaklığına bakar', () {
    final brand = SourceBrand.of('Hugging Face');
    expect(brand.resolve(AppPalette.dark), brand.onDark);
    expect(brand.resolve(AppPalette.light), brand.onLight);
  });
}
