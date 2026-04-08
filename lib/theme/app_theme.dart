import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Inter'),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
      ),
      cardColor: AppColors.lightSurface,
      dividerColor: base.colorScheme.outlineVariant,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: base.colorScheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: base.colorScheme.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Inter'),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
      ),
      cardColor: AppColors.darkSurface,
      dividerColor: base.colorScheme.outlineVariant,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: base.colorScheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: base.colorScheme.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
