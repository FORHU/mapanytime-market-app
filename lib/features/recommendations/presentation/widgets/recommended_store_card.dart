import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/card_badges.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
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

  final StoreEntity store;
  final VoidCallback? onTap;
  final VoidCallback? onVisit;

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl;

    return Material(
      color: AppColors.ui.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            boxShadow: AppEffects.cardShadow,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.brMd,
                child: logoUrl != null
                    ? NetworkImageBox(url: logoUrl, width: 84, height: 84)
                    : Container(
                        width: 84,
                        height: 84,
                        color: colorForStore(store).withValues(alpha: 0.18),
                        alignment: Alignment.center,
                        child: Icon(
                          iconForStore(store),
                          size: 32,
                          color: colorForStore(store),
                        ),
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
                          (store.rating ?? 0).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Gap(2),
                    Text(
                      store.categoryName ?? 'Store',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.tertiary,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Row(
                      children: [
                        _OpenDot(isOpen: store.isOpen ?? true),
                        const Gap(AppSpacing.md),
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.text.tertiary,
                        ),
                        const Gap(2),
                        Text(
                          '${store.distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.text.tertiary,
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
    final color = isOpen ? AppColors.status.success : AppColors.text.tertiary;
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
      color: AppColors.ink.withValues(alpha: 0.1),
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 7,
          ),
          child: Text(
            'Visit',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
