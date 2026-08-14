import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/components/button_theme.dart';
import 'package:mapanytime_market_app/theme/components/card_theme.dart';
import 'package:mapanytime_market_app/theme/components/input_theme.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/typography.dart';

class LightTheme {
  LightTheme._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Explicit Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.brand.primary,
        secondary: AppColors.brand.secondary,
        surface: AppColors.ui.surface,
        surfaceContainerHighest: AppColors.ui.surfaceElevated,
        onSurfaceVariant: AppColors.text.secondary,
        outline: AppColors.ui.border,
        error: AppColors.status.error,
        onPrimary: AppColors.ui.surface,
        onSecondary: AppColors.ui.surface,
        onSurface: AppColors.text.primary,
        onError: AppColors.ui.surface,
      ),

      scaffoldBackgroundColor: AppColors.ui.background,

      // Global Typography
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.text.primary,
        displayColor: AppColors.text.primary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.ui.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text.primary),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColors.text.primary,
        ),
      ),

      // Components
      elevatedButtonTheme: AppButtonTheme.elevated,
      inputDecorationTheme: AppInputTheme.inputDecoration,
      cardTheme: AppCardTheme.cardTheme,
    );
  }
}
