import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';
import '../tokens/app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData get light => _build(AppPalette.light);

  /// İki tema da **tek gövdeden** kuruluyor.
  ///
  /// Ayrı ayrı yazılsalardı biri güncellenip diğeri unutulurdu; bu, iki temalı
  /// uygulamalarda en sık görülen kusur. Fark yalnız [palette] — biçimin
  /// tamamı ortak.
  static ThemeData _build(AppPalette palette) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: palette.brightness,
          surface: palette.surface,
          error: palette.critical,
        ).copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          secondary: palette.aiAccent,
          surface: palette.surface,
          outline: palette.outline,
          onSurface: palette.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      extensions: [palette],
      textTheme: TextTheme(
        displaySmall: AppTypography.display.copyWith(
          color: palette.textPrimary,
        ),
        headlineMedium: AppTypography.headline.copyWith(
          color: palette.textPrimary,
        ),
        titleLarge: AppTypography.title.copyWith(color: palette.textPrimary),
        bodyMedium: AppTypography.body.copyWith(color: palette.textPrimary),
        labelMedium: AppTypography.label.copyWith(color: palette.textSecondary),
      ),
      dividerColor: palette.outline,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        // Metin alanının çerçevesi, alanın nerede başlayıp bittiğini anlatan
        // **tek** işaret; WCAG 1.4.11 burada 3:1 istiyor. Dekoratif `outline`
        // (koyu temada 1.45:1) bu işi göremez.
        border: const OutlineInputBorder(borderRadius: AppRadius.smallBorder),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: BorderSide(color: palette.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        // Seçili sekmenin arkasındaki hap. Marka renginin %15 şeffafı — iki
        // temada da yüzeyden ayrılıyor ama üstündeki etiketi bastırmıyor.
        indicatorColor: palette.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.navLabel.copyWith(color: palette.textSecondary),
        ),
      ),
      // Material'in varsayılan SnackBar'ı temanın tersi zeminlidir ve koyu
      // temanın üstünde beyaz bir bant olarak çıkar. Uygulama genelinde tek
      // bildirim biçimi olduğu için palete bağlıyoruz.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceHigh,
        contentTextStyle: AppTypography.body.copyWith(
          color: palette.textPrimary,
        ),
        actionTextColor: palette.primary,
      ),
    );
  }
}
