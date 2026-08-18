import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/components/button_theme.dart';
import 'package:mapanytime_market_app/theme/components/card_theme.dart';
import 'package:mapanytime_market_app/theme/components/input_theme.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/typography.dart';

/// The app's canonical (and only) theme — a light canvas with a single ink
/// accent, per DESIGN.md. Wired into [MaterialApp] via `AppTheme.light` /
/// `ThemeMode.light` in `app.dart`.
class LightTheme {
  LightTheme._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Explicit Color Scheme — ink-on-white, no brand hue.
      colorScheme: ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.text.onInk,
        secondary: AppColors.ink,
        onSecondary: AppColors.text.onInk,
        surface: AppColors.ui.surface,
        onSurface: AppColors.text.primary,
        onSurfaceVariant: AppColors.text.secondary,
        surfaceContainerHighest: AppColors.ui.surfaceMuted,
        outline: AppColors.ui.borderHairline,
        error: AppColors.status.error,
        onError: AppColors.text.onInk,
      ),

      scaffoldBackgroundColor: AppColors.ui.background,

      // Global Typography — same Inter scale as before, re-based on ink text.
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.text.primary,
        displayColor: AppColors.text.primary,
      ),

      // AppBar — transparent/zero-elevation is set per-screen by
      // ModernAppBar; this is the fallback for any bare AppBar.
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
