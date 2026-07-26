import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.surface,
      error: AppColors.critical,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.aiAccent,
        surface: AppColors.surface,
        outline: AppColors.outline,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: const TextTheme(
        displaySmall: AppTypography.display,
        headlineMedium: AppTypography.headline,
        titleLarge: AppTypography.title,
        bodyMedium: AppTypography.body,
        labelMedium: AppTypography.label,
      ),
      dividerColor: AppColors.outline,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: AppRadius.smallBorder),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0x2600F0FF),
        labelTextStyle: WidgetStatePropertyAll(AppTypography.label),
      ),
    );
  }
}
