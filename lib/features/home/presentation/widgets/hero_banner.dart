import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Large gradient hero introducing the map-first discovery experience, with
/// live stats and the primary CTAs.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    required this.nearbyCount,
    required this.openNowCount,
    required this.dealsCount,
    this.onOpenMap,
    this.onBrowseCategories,
    super.key,
  });

  final int nearbyCount;
  final int openNowCount;
  final int dealsCount;
  final VoidCallback? onOpenMap;
  final VoidCallback? onBrowseCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.brXl,
        boxShadow: AppEffects.primaryGlow,
      ),
      child: Stack(
        children: [
          // Decorative compass illustration behind the content.
          Positioned(
            right: -16,
            top: -10,
            child: Icon(
              Icons.explore_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Discover stores\naround you',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  Hero(
                    tag: 'home-map-illustration',
                    child: Icon(
                      Icons.map_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 56,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                'Explore nearby merchants, restaurants, services and '
                'local deals in real time.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const Gap(AppSpacing.lg),
              _StatsRow(
                nearby: nearbyCount,
                openNow: openNowCount,
                deals: dealsCount,
              ),
              const Gap(AppSpacing.lg),
              _PrimaryCta(onTap: onOpenMap),
              const Gap(AppSpacing.sm),
              _SecondaryCta(onTap: onBrowseCategories),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.nearby,
    required this.openNow,
    required this.deals,
  });

  final int nearby;
  final int openNow;
  final int deals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(value: '$nearby', label: 'Nearby'),
        _divider(),
        _Stat(value: '$openNow', label: 'Open Now'),
        _divider(),
        _Stat(value: '$deals', label: 'Deals'),
      ],
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    color: Colors.white.withValues(alpha: 0.25),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, size: 20, color: AppColors.brand.primary),
              const Gap(AppSpacing.sm),
              Text(
                'Open Live Map',
                style: TextStyle(
                  color: AppColors.brand.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: const Text(
            'Browse Categories',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
