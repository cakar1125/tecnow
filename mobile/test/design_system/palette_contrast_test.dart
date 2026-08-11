import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/design_system/theme/app_theme.dart';
import 'package:tecos/design_system/tokens/app_palette.dart';

/// Renk kararlarının kapısı.
///
/// Palet iki temaya çıkarken renkler **tahminle** değil ölçümle seçildi;
/// bu dosya o ölçümü kalıcı kılıyor. Renk değiştirmek serbest — sessizce
/// okunmaz hale getirmek değil.
///
/// Somut örnek: koyu temanın `warning` kehribarı (#F59E0B) açık temada beyaz
/// üstünde **2.15:1** veriyor, yani okunmuyor. Renkleri doğrudan taşımak en
/// kolay yoldu ve bu test onu durdururdu.
///
/// Ölçüt WCAG 2.1: normal metin ≥ 4.5:1 (AA), arayüz sınırı ≥ 3:1 (1.4.11).

/// WCAG 2.1 bağıl parlaklık.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  /// Hesabın kendisi doğru mu? Bilinen iki uç nokta.
  group('kontrast hesabı', () {
    test('siyah–beyaz 21:1', () {
      expect(
        contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
    });

    test('aynı renk 1:1', () {
      const color = Color(0xFF3A7BD5);
      expect(contrast(color, color), closeTo(1, 0.001));
    });
  });

  for (final (name, palette) in [
    ('koyu', AppPalette.dark),
    ('açık', AppPalette.light),
  ]) {
    group('$name tema', () {
      /// Metin çiftleri: her metin rengi, üstüne yazıldığı her zeminde.
      test('metin AA eşiğini (4.5:1) geçer', () {
        final grounds = {
          'zemin': palette.background,
          'yüzey': palette.surface,
          'yüzeyYüksek': palette.surfaceHigh,
        };
        final foregrounds = {
          'birincil metin': palette.textPrimary,
          'ikincil metin': palette.textSecondary,
          'marka': palette.primary,
          'ai vurgusu': palette.aiAccent,
          'başarı': palette.success,
          'uyarı': palette.warning,
          'kritik': palette.critical,
        };

        for (final ground in grounds.entries) {
          for (final foreground in foregrounds.entries) {
            final ratio = contrast(foreground.value, ground.value);
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason:
                  '$name: ${foreground.key} / ${ground.key} = '
                  '${ratio.toStringAsFixed(2)}:1 — AA eşiği 4.5:1',
            );
          }
        }
      });

      /// Dolgu üstündeki metin: birincil düğme ve yıkıcı düğme.
      test('dolgu üstündeki metin AA eşiğini geçer', () {
        for (final fill in {
          'marka dolgusu': palette.primary,
          'kritik dolgu': palette.critical,
        }.entries) {
          final ratio = contrast(palette.onPrimary, fill.value);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$name: onPrimary / ${fill.key} = '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      });

      /// WCAG 1.4.11: sınırın taşıdığı bilgi başka türlü anlatılmıyorsa 3:1.
      /// [AppPalette.outlineStrong] tam olarak o iş için var.
      test('outlineStrong arayüz eşiğini (3:1) geçer', () {
        for (final ground in {
          'zemin': palette.background,
          'yüzey': palette.surface,
        }.entries) {
          final ratio = contrast(palette.outlineStrong, ground.value);
          expect(
            ratio,
            greaterThanOrEqualTo(3),
            reason:
                '$name: outlineStrong / ${ground.key} = '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      });

      /// Dekoratif `outline` **bilerek** düşük kontrastlı. Bu test onun
      /// yanlışlıkla tek ayırıcı gibi kullanılabilecek kadar güçlenmediğini
      /// değil, `outlineStrong` ile karıştırılmadığını ölçüyor: ikisi eşitse
      /// ayrım anlamını yitirir ve biri gereksiz hale gelir.
      test('outline ile outlineStrong farklı renklerdir', () {
        expect(palette.outline, isNot(palette.outlineStrong));
      });
    });
  }

  /// Temanın kendisi paleti taşıyor mu? `context.palette` bunun üstünde
  /// duruyor; kayıt unutulursa uygulama açılışta atar.
  group('tema paleti taşır', () {
    test('koyu tema', () {
      expect(AppTheme.dark.extension<AppPalette>(), AppPalette.dark);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    test('açık tema', () {
      expect(AppTheme.light.extension<AppPalette>(), AppPalette.light);
      expect(AppTheme.light.brightness, Brightness.light);
    });

    /// İki tema **aynı** paleti taşımamalı. `_build` tek gövdeden kurulduğu
    /// için yanlış argüman geçmek sessiz bir hata olurdu: uygulama iki
    /// temayı da koyu çizerdi ve hiçbir şey kırılmazdı.
    test('iki tema farklı palet taşır', () {
      expect(
        AppTheme.light.extension<AppPalette>(),
        isNot(AppTheme.dark.extension<AppPalette>()),
      );
    });
  });

  /// `lerp` tema geçişinde kullanılıyor. Uç noktalar korunmalı, yoksa geçiş
  /// bittiğinde renkler hedefe tam oturmaz.
  group('lerp', () {
    test('uç noktalar korunur', () {
      expect(AppPalette.dark.lerp(AppPalette.light, 0), AppPalette.dark);
      expect(AppPalette.dark.lerp(AppPalette.light, 1), AppPalette.light);
    });

    /// Parlaklık karıştırılmaz, atlar: "yarı koyu" diye bir parlaklık yok ve
    /// gölge yoğunluğu gibi ona bakan kararlar iki değerden birini görmeli.
    test('parlaklık ayrık atlar', () {
      expect(
        AppPalette.dark.lerp(AppPalette.light, 0.49).brightness,
        Brightness.dark,
      );
      expect(
        AppPalette.dark.lerp(AppPalette.light, 0.51).brightness,
        Brightness.light,
      );
    });
  });
}
