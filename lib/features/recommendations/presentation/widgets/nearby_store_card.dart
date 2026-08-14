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

/// A rich merchant card for the horizontal "Nearby Merchants" rail.
class NearbyStoreCard extends StatelessWidget {
  const NearbyStoreCard({
    required this.store,
    this.onTap,
    this.onVisit,
    this.onFavorite,
    super.key,
  });

  final StoreEntity store;
  final VoidCallback? onTap;
  final VoidCallback? onVisit;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ui.surfaceDark,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Ink(
          width: 260,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.ui.borderDark),
            boxShadow: AppEffects.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cover(store: store, onFavorite: onFavorite),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      store.categoryName ?? 'Store',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text.tertiaryDark,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Row(
                      children: [
                        const RatingPill(),
                        const Gap(6),
                        Text(
                          (store.rating ?? 0).toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.text.tertiaryDark,
                        ),
                        const Gap(2),
                        Text(
                          '${store.distance.toStringAsFixed(1)} km away',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.text.tertiaryDark,
                              ),
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.md),
                    _VisitButton(onTap: onVisit),
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

class _Cover extends StatelessWidget {
  const _Cover({required this.store, this.onFavorite});

  final StoreEntity store;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl;

    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorForStore(store).withValues(alpha: 0.18),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              iconForStore(store),
              size: 40,
              color: colorForStore(store),
            ),
          ),
          if (store.isOpen != null)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: StatusBadge(isOpen: store.isOpen!),
            ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: FavoriteButton(onTap: onFavorite),
          ),
          if (logoUrl != null)
            Positioned(
              left: AppSpacing.md,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.ui.surfaceDark,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: NetworkImageBox(url: logoUrl, width: 36, height: 36),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisitButton extends StatelessWidget {
  const _VisitButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.brand.primary,
        borderRadius: AppRadius.brPill,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brPill,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              'Visit Store',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
