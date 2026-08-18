import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Design tokens — elevation, shadows, and the one surviving gradient.
class AppEffects {
  AppEffects._();

  /// Card / floating-chrome shadow — soft and diffuse, tuned for a white
  /// canvas rather than the old near-black one.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  /// Small raised elements — buttons, icon buttons.
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Photo-legibility scrim behind text on promo/deal banners — the one
  /// gradient in the system. Never use for a brand wash, a button fill, or
  /// a "pop" treatment.
  static const LinearGradient promoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000D0D0F), Color(0xBF0D0D0F)],
  );
}
