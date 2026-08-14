import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

/// The MapAnytime brand mark — a gradient rounded badge with a map-pin glyph,
/// sitting on a soft ambient glow. Used on the auth screens.
class AuthLogo extends StatelessWidget {
  const AuthLogo({this.size = 84, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.2,
      height: size * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow — a separate soft-edged surface behind the badge,
          // not a second shadow stacked on the badge itself.
          Container(
            width: size * 1.8,
            height: size * 1.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.brand.primary.withValues(alpha: 0.28),
                  AppColors.brand.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppEffects.primaryGlow,
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
