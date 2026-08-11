import 'package:flutter/material.dart';

import 'app_palette.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Erişilebilirlik ölçüleri.
abstract final class AppTouchTarget {
  /// `QUALITY_GATES.md`: "Minimum 44×44 dokunma alanı".
  ///
  /// Kural uzun süre yazılıydı ama **hiçbir yerde ölçülmüyordu**. Ölçüldüğünde
  /// (2026-07-28) Ana Sayfa'nın dört sekmesi 39 dp çıktı. Kapı artık
  /// `test/app/touch_target_test.dart` içinde her rotayı geziyor.
  ///
  /// Material'in kendi bileşenleri (`FilterChip`, `IconButton`) görünen
  /// alandan geniş bir dokunma alanı ekler ve kuralı kendiliğinden sağlar;
  /// ham `InkWell` eklemez. Bu sabit ham kontroller içindir.
  static const minimum = 44.0;
}

abstract final class AppRadius {
  static const small = Radius.circular(8);
  static const card = Radius.circular(12);
  static const large = Radius.circular(16);
  static const featured = Radius.circular(24);
  static const smallBorder = BorderRadius.all(small);
  static const cardBorder = BorderRadius.all(card);
  static const largeBorder = BorderRadius.all(large);
  static const featuredBorder = BorderRadius.all(featured);
}

/// Metnin **biçimi**: punto, ağırlık, satır yüksekliği, yazı ailesi.
///
/// Buradaki renkler yalnız birer taban değer. Uygulamada hiçbir widget bu
/// sınıfı doğrudan kullanmaz — renk temaya göre değişiyor ve doğrudan
/// kullanım koyu temanın rengini açık temaya taşır. Widget'ların erişim yolu
/// `context.text` (`app_text.dart`); tema da `AppTheme._build` içinde
/// renkleri paletten geçirerek `TextTheme`'i kurar.
///
/// Kural bir yorumla değil kapıyla korunuyor:
/// `test/design_system/typography_usage_test.dart`.
abstract final class AppTypography {
  /// Taban renk kaynağı.
  ///
  /// Koyu palet **tek gerçek kaynak** olduğu için buradan okunuyor. İkinci
  /// bir renk listesi (eski `AppColors`) tutulsaydı ikisi ayrışırdı; bu tam
  /// olarak paletin çözdüğü sorun.
  static const _ink = AppPalette.dark;

  static final _base = TextStyle(
    color: _ink.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    textBaseline: TextBaseline.alphabetic,
  );
  static final display = TextStyle(
    inherit: false,
    color: _ink.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 32,
    textBaseline: TextBaseline.alphabetic,
    height: 1.18,
    fontWeight: FontWeight.w700,
  );
  static final headline = TextStyle(
    inherit: false,
    color: _ink.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 24,
    textBaseline: TextBaseline.alphabetic,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
  static final title = TextStyle(
    inherit: false,
    color: _ink.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 18,
    textBaseline: TextBaseline.alphabetic,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );
  static final body = TextStyle(
    inherit: false,
    color: _ink.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 14,
    textBaseline: TextBaseline.alphabetic,
    height: 1.5,
  );
  static final label = TextStyle(
    inherit: false,
    color: _ink.textSecondary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 12,
    textBaseline: TextBaseline.alphabetic,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );

  /// Alt navigasyon etiketi.
  ///
  /// `label` (12sp) ile ölçülen "Kaydedilenler" 79.8 dp yer kaplar; 360 dp
  /// ekranda beş bölmeli navigasyonda bir bölme 72 dp'dir ve etiket kelimenin
  /// ortasından ikinci satıra taşar. Sıkıştırılmış bu varyant 69.2 dp'ye
  /// iner ve 360/390/430 dp'de tek satırda kalır.
  /// Ölçüm ve regresyon kilidi: `test/design_system/bottom_navigation_test.dart`.
  static final navLabel = TextStyle(
    inherit: false,
    color: _ink.textSecondary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 11,
    letterSpacing: -0.3,
    textBaseline: TextBaseline.alphabetic,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );
  static final technical = TextStyle(
    inherit: false,
    color: _ink.textSecondary,
    fontFamily: 'JetBrains Mono',
    fontFamilyFallback: ['monospace'],
    fontSize: 12,
    textBaseline: TextBaseline.alphabetic,
    height: 1.45,
  );
  static TextStyle get bodyMuted =>
      _base.copyWith(fontSize: 14, height: 1.5, color: _ink.textSecondary);
}

/// Gölgeler de temaya bağlı.
///
/// Sabit oldukları sürece açık temada iki şey bozuluyordu: siyah gölge açık
/// zeminde kirli bir gri halka bırakıyor, ve marka parıltısı camgöbeği kalıp
/// açık temanın koyu turkuazıyla çelişiyordu. İkisi de artık paletten
/// besleniyor — bu yüzden sabit değil, fonksiyon.
abstract final class AppShadows {
  static List<BoxShadow> card(AppPalette palette) => [
    BoxShadow(
      color: palette.shadow,
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Marka parıltısı: açılış ve karşılama ekranındaki simgenin arkasında.
  static List<BoxShadow> brandGlow(AppPalette palette) => [
    BoxShadow(color: palette.primary.withValues(alpha: 0.18), blurRadius: 20),
  ];
}

abstract final class AppDurations {
  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
}

abstract final class AppBreakpoints {
  static const compactMin = 360.0;
  static const reference = 390.0;
  static const comfortable = 430.0;
}
