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

  /// White product card on the page background: a tight contact layer plus
  /// a lifted indigo-tinted one.
  static List<BoxShadow> get productCardShadow => [
    BoxShadow(
      color: const Color(0xFF141C50).withValues(alpha: 0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.22),
      blurRadius: 24,
      spreadRadius: -12,
      offset: const Offset(0, 12),
    ),
  ];

  /// Tight contact shadow for small white overlays on a card cover — status
  /// chips, the heart button, the store avatar ring.
  static List<BoxShadow> get overlayShadow => [
    BoxShadow(
      color: _contact.withValues(alpha: 0.2),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  /// Lift for a white icon tile sitting on a tinted cover; scales with the
  /// tile so small and large tiles read the same.
  static List<BoxShadow> tileShadow(double size) {
    final lift = size / 9;
    return [
      BoxShadow(
        color: _contact.withValues(alpha: 0.28),
        blurRadius: lift * 2.2,
        spreadRadius: -lift,
        offset: Offset(0, lift),
      ),
    ];
  }

  /// Indigo-black tint shared by the contact shadows above.
  static const Color _contact = Color(0xFF141C50);

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
