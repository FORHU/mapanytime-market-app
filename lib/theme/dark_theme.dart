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

      // Explicit Color Scheme — dark-premium palette
      colorScheme: ColorScheme.dark(
        primary: AppColors.brand.primary,
        onPrimary: Colors.white,
        secondary: AppColors.brand.secondary,
        onSecondary: Colors.white,
        surface: AppColors.ui.surfaceDark,
        onSurface: AppColors.text.primaryDark,
        onSurfaceVariant: AppColors.text.secondaryDark,
        surfaceContainerHighest: AppColors.ui.surfaceElevatedDark,
        outline: AppColors.ui.borderDark,
        error: AppColors.status.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.ui.backgroundDark,
      canvasColor: AppColors.ui.backgroundDark,
      dividerTheme: DividerThemeData(
        color: AppColors.ui.borderDark,
        thickness: 1,
        space: 1,
      ),

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
