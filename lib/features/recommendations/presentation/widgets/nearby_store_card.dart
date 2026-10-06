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
///
/// The card itself is not tappable: only Visit Store navigates, and the
/// heart only saves/unsaves.
class NearbyStoreCard extends StatelessWidget {
  const NearbyStoreCard({
    required this.store,
    this.onVisit,
    this.onFavorite,
    this.isFavorite = false,
    super.key,
  });

  final StoreEntity store;
  final VoidCallback? onVisit;
  final VoidCallback? onFavorite;

  /// Whether [store] is in the buyer's saved stores (filled heart).
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ui.surface,
      borderRadius: AppRadius.brCard,
      child: Ink(
        width: 260,
        // The fill sits above the shadow; without it the indigo shadow
        // shows through the card body (Ink paints over the Material).
        decoration: BoxDecoration(
          color: AppColors.ui.surface,
          borderRadius: AppRadius.brCard,
          boxShadow: AppEffects.productCardShadow,
        ),
        // Foreground so the outline stays crisp over the tinted cover.
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.ui.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cover(
                store: store,
                isFavorite: isFavorite,
                onFavorite: onFavorite,
              ),
              Padding(
                // Extra top room clears the avatar overlapping the cover.
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      store.categoryName ?? 'Store',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text.secondary,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Row(
                      children: [
                        RatingPill(rating: store.rating ?? 0),
                        const Spacer(),
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.text.secondary,
                        ),
                        const Gap(2),
                        Flexible(
                          child: Text(
                            '${store.distance.toStringAsFixed(1)} km away',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.text.secondary),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
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
  const _Cover({
    required this.store,
    required this.isFavorite,
    this.onFavorite,
  });

  final StoreEntity store;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final color = colorForStore(store);

    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            alignment: Alignment.center,
            child: IconTile(
              icon: iconForStore(store),
              color: color,
              size: 56,
              radius: 18,
              iconSize: 30,
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
            child: FavoriteButton(onTap: onFavorite, isFavorite: isFavorite),
          ),
          Positioned(
            left: 14,
            bottom: -18,
            child: _LogoAvatar(store: store),
          ),
        ],
      ),
    );
  }
}

/// The store's logo — or its initials on its category color when it has
/// none — in a white ring overlapping the cover's bottom edge.
class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({required this.store});

  final StoreEntity store;

  static const _size = 40.0;
  static const _ring = 3.0;
  static const double _inner = _size - _ring * 2;

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl;

    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(_ring),
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        shape: BoxShape.circle,
        boxShadow: AppEffects.overlayShadow,
      ),
      child: ClipOval(
        child: logoUrl != null
            ? NetworkImageBox(url: logoUrl, width: _inner, height: _inner)
            : Container(
                color: colorForStore(store),
                alignment: Alignment.center,
                child: Text(
                  monogramForStore(store),
                  style: TextStyle(
                    color: AppColors.text.onInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
        color: AppColors.ink,
        borderRadius: AppRadius.brPill,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brPill,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Visit Store',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.text.onInk,
                  ),
                ),
                const Gap(6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.text.onInk,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
