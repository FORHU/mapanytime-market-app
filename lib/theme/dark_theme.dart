import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/components/button_theme.dart';
import 'package:mapanytime_market_app/theme/components/card_theme.dart';
import 'package:mapanytime_market_app/theme/components/input_theme.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/typography.dart';

class DarkTheme {
  DarkTheme._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Explicit Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.brand.primary,
        secondary: AppColors.brand.secondary,
        surface: AppColors.ui.surfaceDark,
        error: AppColors.status.error,
        onPrimary: AppColors.ui.surface,
        onSecondary: AppColors.ui.surface,
        onSurface: AppColors.text.primaryDark,
        onError: AppColors.ui.surface,
      ),

      scaffoldBackgroundColor: AppColors.ui.backgroundDark,

      // Global Typography
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.text.primaryDark,
        displayColor: AppColors.text.primaryDark,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.ui.backgroundDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text.primaryDark),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColors.text.primaryDark,
        ),
      ),

      // Components (These will automatically adapt colors based on Context,
      // but we reuse the shapes)
      elevatedButtonTheme: AppButtonTheme.elevated,
      inputDecorationTheme: AppInputTheme.inputDecoration,
      cardTheme: AppCardTheme.cardTheme,
    );
  }
}
