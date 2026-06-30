import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A large gradient "Explore" pill FAB that opens the live map.
class ExploreFab extends StatelessWidget {
  const ExploreFab({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.brPill,
            boxShadow: AppEffects.primaryGlow,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_rounded, color: Colors.white, size: 22),
                Gap(AppSpacing.sm),
                Text(
                  'Explore',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
