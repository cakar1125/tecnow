import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0A0C10);
  static const surface = Color(0xFF11151B);
  static const surfaceHigh = Color(0xFF181D25);
  static const outline = Color(0xFF2B3440);
  static const primary = Color(0xFF00F0FF);
  static const aiAccent = Color(0xFFA855F7);
  static const textPrimary = Color(0xFFF7FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
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

abstract final class AppTypography {
  static const _base = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    textBaseline: TextBaseline.alphabetic,
  );
  static const display = TextStyle(
    inherit: false,
    color: AppColors.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 32,
    textBaseline: TextBaseline.alphabetic,
    height: 1.18,
    fontWeight: FontWeight.w700,
  );
  static const headline = TextStyle(
    inherit: false,
    color: AppColors.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 24,
    textBaseline: TextBaseline.alphabetic,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    inherit: false,
    color: AppColors.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 18,
    textBaseline: TextBaseline.alphabetic,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    inherit: false,
    color: AppColors.textPrimary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 14,
    textBaseline: TextBaseline.alphabetic,
    height: 1.5,
  );
  static const label = TextStyle(
    inherit: false,
    color: AppColors.textSecondary,
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
  static const navLabel = TextStyle(
    inherit: false,
    color: AppColors.textSecondary,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
    fontSize: 11,
    letterSpacing: -0.3,
    textBaseline: TextBaseline.alphabetic,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );
  static const technical = TextStyle(
    inherit: false,
    color: AppColors.textSecondary,
    fontFamily: 'JetBrains Mono',
    fontFamilyFallback: ['monospace'],
    fontSize: 12,
    textBaseline: TextBaseline.alphabetic,
    height: 1.45,
  );
  static TextStyle get bodyMuted =>
      _base.copyWith(fontSize: 14, height: 1.5, color: AppColors.textSecondary);
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x3D000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const cyanGlow = [BoxShadow(color: Color(0x2E00F0FF), blurRadius: 20)];
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
