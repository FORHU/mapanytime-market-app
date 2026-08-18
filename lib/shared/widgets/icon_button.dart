import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';

/// The app's one icon-affordance shape — a solid ink circle with a white
/// glyph, per DESIGN.md. Used for back buttons, avatar frames, the wishlist
/// heart, the search bar's map-entry trigger, and CTA arrow accents. Don't
/// invent a second icon-button shape (no square chips, no ghost/outline
/// icon buttons) — everything that's "an icon you can tap" uses this.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.iconSize,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
          boxShadow: AppEffects.softShadow,
        ),
        child: Icon(
          icon,
          size: iconSize ?? size * 0.42,
          color: AppColors.text.onInk,
        ),
      ),
    );
  }
}
