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

/// A full-width store row for the vertical "Recommended Stores" list, and
/// for Profile → Saved → Stores.
///
/// The row itself is not tappable: only Visit navigates.
class RecommendedStoreCard extends StatelessWidget {
  const RecommendedStoreCard({
    required this.store,
    this.onVisit,
    this.isSaved,
    this.onToggleSave,
    super.key,
  });

  final StoreEntity store;
  final VoidCallback? onVisit;

  /// Whether [store] is saved. The heart only renders when [onToggleSave] is
  /// set — For You leaves it off; the Saved page passes both.
  final bool? isSaved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl;

    return Material(
      color: AppColors.ui.surface,
      borderRadius: AppRadius.brCard,
      child: Ink(
        // The fill sits above the shadow; without it the indigo shadow
        // shows through the card body (Ink paints over the Material).
        decoration: BoxDecoration(
          color: AppColors.ui.surface,
          borderRadius: AppRadius.brCard,
          boxShadow: AppEffects.productCardShadow,
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.ui.borderCard),
          ),
          child: Padding(
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
                          color: colorForStore(store).withValues(alpha: 0.14),
                          alignment: Alignment.center,
                          child: IconTile(
                            icon: iconForStore(store),
                            color: colorForStore(store),
                          ),
                        ),
                ),
                const Gap(12),
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
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.xs),
                          RatingPill(rating: store.rating ?? 0),
                          if (onToggleSave != null) ...[
                            const Gap(2),
                            _SaveHeart(
                              isSaved: isSaved ?? false,
                              onTap: onToggleSave!,
                            ),
                          ],
                        ],
                      ),
                      const Gap(2),
                      Text(
                        store.categoryName ?? 'Store',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.secondary,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Row(
                        children: [
                          _OpenDot(isOpen: store.isOpen ?? true),
                          const Gap(10),
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.text.secondary,
                          ),
                          const Gap(2),
                          Text(
                            '${store.distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.text.secondary,
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
      ),
    );
  }
}

class _OpenDot extends StatelessWidget {
  const _OpenDot({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.status.success : AppColors.text.secondary;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
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
            horizontal: 14,
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

/// Compact save toggle for the row's title line.
class _SaveHeart extends StatelessWidget {
  const _SaveHeart({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 20,
          color: isSaved ? AppColors.status.error : AppColors.text.secondary,
        ),
      ),
    );
  }
}
