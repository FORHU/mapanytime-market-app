import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Design tokens — elevation, shadows, blur and glow effects.
class AppEffects {
  AppEffects._();

  /// Standard blur for glassmorphic surfaces. Keep blur layers limited on
  /// lists for performance (see docs/progress gotchas).
  static const double glassBlur = 18;

  static ImageFilter get glassFilter =>
      ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur);

  /// Soft, low-opacity shadow used by floating cards.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  /// Tighter shadow for smaller raised elements (chips, FABs).
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  /// Colored glow for primary CTAs / active markers.
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: AppColors.brand.primary.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
