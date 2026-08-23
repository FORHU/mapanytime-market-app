import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/card_badges.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/price_tag.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A vertical product card: image, name, price and store/distance. Still flat
/// — no shadow, text sits directly on the page's canvas — but the image gets
/// a subtle ink border (8% alpha, matching `AppEffects.cardShadow`'s
/// strength) since a white product photo on the near-white background
/// otherwise has no visible edge. `AppColors.ui.borderHairline` was tried
/// first and was too close to the placeholder's own fill color to read as
/// a border at all.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.name,
    required this.imageUrl,
    required this.price,
    this.storeName,
    this.distanceKm,
    this.onTap,
    this.width = 168,
    this.badgeLabel,
    this.isSaved,
    this.onToggleSave,
    super.key,
  });

  final String name;
  final String imageUrl;
  final num price;
  final String? storeName;
  final double? distanceKm;
  final VoidCallback? onTap;
  final double width;

  /// When set (e.g. "20% OFF"), overlays a [DiscountBadge] on the image to
  /// highlight that this product is linked to an active merchant ad.
  final String? badgeLabel;

  /// Whether this product is in the buyer's wishlist. The heart overlay only
  /// renders when [onToggleSave] is non-null — callers that don't pass it
  /// (most existing usages) see no change at all.
  final bool? isSaved;

  /// Save/unsave this product. Opt-in: pass both this and [isSaved] to show
  /// the heart; omit either and the card renders exactly as before.
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.08),
                ),
              ),
              child: Stack(
                children: [
                  NetworkImageBox(
                    url: imageUrl,
                    height: width * 0.9,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                  ),
                  if (badgeLabel != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DiscountBadge(label: badgeLabel!),
                    ),
                  if (onToggleSave != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _SaveButton(
                        isSaved: isSaved ?? false,
                        onTap: onToggleSave!,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      color: AppColors.text.primary,
                    ),
                  ),
                  const Gap(6),
                  if (storeName != null)
                    Text(
                      storeName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.text.tertiary,
                      ),
                    ),
                  const Gap(AppSpacing.sm),
                  Row(
                    children: [
                      PriceTag(amount: price, fontSize: 15),
                      const Spacer(),
                      if (distanceKm != null)
                        Text(
                          '${distanceKm!.toStringAsFixed(1)} km',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The heart overlay. A `Material`+`InkWell` sibling stacked on top of the
/// card's image — Stack hit-testing stops at the first (topmost) child that
/// claims a point, so this exclusively captures the tap; the card's own
/// `onTap` never sees it. Don't restructure this as a child *inside* the
/// card's `GestureDetector` — that would let both fire for the same tap.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 16,
            color: isSaved ? Colors.red : AppColors.text.tertiary,
          ),
        ),
      ),
    );
  }
}
