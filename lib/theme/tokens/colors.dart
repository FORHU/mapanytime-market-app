import 'package:flutter/material.dart';

/// Design tokens — colors. Dark-premium marketplace palette.
///
/// The app runs dark-only; the light values are kept only as a fallback so the
/// light [ThemeData] still builds. New UI should read these via the theme.
class AppColors {
  AppColors._();

  static const brand = _Brand();
  static const ui = _UI();
  static const text = _Text();
  static const status = _Status();

  /// Primary brand gradient (blue → purple). Use for hero CTAs and accents.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F5DFF), Color(0xFF8A5CFF)],
  );

  /// Subtle surface gradient for large glass panels.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F2B), Color(0xFF12151D)],
  );
}

class _Brand {
  const _Brand();

  /// Primary accent — #4F5DFF.
  Color get primary => const Color(0xFF4F5DFF);

  /// Gradient end / secondary accent — purple.
  Color get secondary => const Color(0xFF8A5CFF);

  /// A brighter tint for pressed/hover and glows.
  Color get primaryBright => const Color(0xFF6B78FF);
}

class _UI {
  const _UI();

  // --- Dark (primary palette) ---
  /// App background — #0B0D13.
  Color get backgroundDark => const Color(0xFF0B0D13);

  /// Card / surface — #151922.
  Color get surfaceDark => const Color(0xFF151922);

  /// Slightly raised surface (nested cards, inputs).
  Color get surfaceElevatedDark => const Color(0xFF1C212C);

  /// Hairline borders / dividers (white at low opacity).
  Color get borderDark => const Color(0x1FFFFFFF); // ~12% white

  /// Translucent fill for glassmorphism.
  Color get glassDark => const Color(0x14FFFFFF); // ~8% white

  // --- Light (fallback only) ---
  Color get background => const Color(0xFFF6F7FB);
  Color get surface => const Color(0xFFFFFFFF);
}

class _Text {
  const _Text();

  // --- Dark (primary) ---
  /// Near-white primary text.
  Color get primaryDark => const Color(0xFFF5F6FA);

  /// Muted secondary text.
  Color get secondaryDark => const Color(0xFF9AA0AE);

  /// Subtle labels / captions.
  Color get tertiaryDark => const Color(0xFF6B7280);

  // --- Light (fallback) ---
  Color get primary => const Color(0xFF1A1C22);
  Color get secondary => const Color(0xFF4A4E5A);
}

class _Status {
  const _Status();
  Color get error => const Color(0xFFF87171);
  Color get success => const Color(0xFF34D399);
  Color get warning => const Color(0xFFFBBF24);
}
