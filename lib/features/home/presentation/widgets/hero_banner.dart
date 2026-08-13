import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Large gradient hero introducing the map-first discovery experience.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    required this.nearbyCount,
    required this.openNowCount,
    required this.dealsCount,
    this.onOpenMap,
    super.key,
  });

  final int nearbyCount;
  final int openNowCount;
  final int dealsCount;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.brXl,
        boxShadow: AppEffects.primaryGlow,
      ),
      child: Stack(
        children: [
          // Decorative element anchored to bottom-right, away from content.
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              Icons.explore_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Discover stores\naround you',
                      style: tt.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.lg),
              Row(
                children: [
                  _StatPill(
                    icon: Icons.storefront_rounded,
                    value: nearbyCount,
                    label: 'Nearby',
                  ),
                  const Gap(AppSpacing.sm),
                  _StatPill(
                    icon: Icons.circle,
                    value: openNowCount,
                    label: 'Open now',
                  ),
                  const Gap(AppSpacing.sm),
                  _StatPill(
                    icon: Icons.local_offer_rounded,
                    value: dealsCount,
                    label: 'Deals',
                  ),
                ],
              ),
              const Gap(AppSpacing.lg),
              _OpenMapButton(onTap: onOpenMap),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
          const Gap(5),
          Text(
            '$value $label',
            style: tt.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenMapButton extends StatelessWidget {
  const _OpenMapButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, size: 18, color: AppColors.brand.primary),
              const Gap(AppSpacing.sm),
              Text(
                'Open Live Map',
                style: tt.labelLarge?.copyWith(color: AppColors.brand.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
