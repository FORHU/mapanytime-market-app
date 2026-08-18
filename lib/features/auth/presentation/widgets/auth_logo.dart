import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

/// The MapAnytime brand mark — a solid ink rounded badge. Used on the auth
/// screens.
class AuthLogo extends StatelessWidget {
  const AuthLogo({this.size = 84, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppEffects.cardShadow,
      ),
      child: Icon(
        Icons.storefront_rounded,
        size: size * 0.5,
        color: AppColors.text.onInk,
      ),
    );
  }
}
