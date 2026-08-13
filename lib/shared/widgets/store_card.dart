import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A horizontal store card: logo, name, rating, distance and open status.
class StoreCard extends StatelessWidget {
  const StoreCard({
    required this.name,
    required this.imageUrl,
    this.rating,
    this.distanceKm,
    this.category,
    this.isOpen = true,
    this.onTap,
    super.key,
  });

  final String name;
  final String imageUrl;
  final double? rating;
  final double? distanceKm;
  final String? category;
  final bool isOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.ui.surfaceDark,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.ui.borderDark),
          boxShadow: AppEffects.cardShadow,
        ),
        child: Row(
          children: [
            NetworkImageBox(
              url: imageUrl,
              width: 64,
              height: 64,
              borderRadius: AppRadius.brMd,
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text.primaryDark,
                          ),
                        ),
                      ),
                      _OpenBadge(isOpen: isOpen),
                    ],
                  ),
                  const Gap(6),
                  Row(
                    children: [
                      if (rating != null) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: AppColors.status.warning,
                        ),
                        const Gap(3),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: tt.labelMedium?.copyWith(
                            color: AppColors.text.secondaryDark,
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                      ],
                      if (category != null)
                        Expanded(
                          child: Text(
                            category!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.text.tertiaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (distanceKm != null) ...[
                    const Gap(6),
                    Text(
                      '${distanceKm!.toStringAsFixed(1)} km away',
                      style: tt.labelMedium?.copyWith(
                        color: AppColors.brand.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen
        ? AppColors.status.success
        : AppColors.text.tertiaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
