import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/recommendations_mock_data.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/card_badges.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A full-width store row for the vertical "Recommended Stores" list.
class RecommendedStoreCard extends StatelessWidget {
  const RecommendedStoreCard({
    required this.store,
    this.onTap,
    this.onVisit,
    super.key,
  });

  final RecommendedStore store;
  final VoidCallback? onTap;
  final VoidCallback? onVisit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ui.surfaceDark,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.ui.borderDark),
            boxShadow: AppEffects.cardShadow,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.brMd,
                child: NetworkImageBox(
                  url: store.imageUrl,
                  width: 84,
                  height: 84,
                ),
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
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const RatingPill(),
                        const Gap(2),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Gap(2),
                    Text(
                      store.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.tertiaryDark,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Row(
                      children: [
                        _OpenDot(isOpen: store.isOpen),
                        const Gap(AppSpacing.md),
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.text.tertiaryDark,
                        ),
                        const Gap(2),
                        Text(
                          '${store.distanceKm} km',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.text.tertiaryDark,
                          ),
                        ),
                        const Spacer(),
                        _VisitButton(onTap: onVisit),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenDot extends StatelessWidget {
  const _OpenDot({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen
        ? AppColors.status.success
        : AppColors.text.tertiaryDark;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(4),
        Text(
          isOpen ? 'Open' : 'Closed',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

class _VisitButton extends StatelessWidget {
  const _VisitButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand.primary.withValues(alpha: 0.15),
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 7,
          ),
          child: Text(
            'Visit',
            style: TextStyle(
              color: AppColors.brand.primaryBright,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
