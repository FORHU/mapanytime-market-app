import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/card_badges.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/price_tag.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A vertical product card: image, name, price and store/distance. Flat —
/// no border or shadow on the card itself, per DESIGN.md; the image and
/// text sit directly on the page's canvas.
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
            Stack(
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
              ],
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
