import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/recommendations/domain/entities/nearby_deal.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/card_badges.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A promotional deal card for the horizontal "Today's Deals" rail.
class DealCard extends StatelessWidget {
  const DealCard({required this.deal, this.onTap, super.key});

  final NearbyDeal deal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = deal.ad.displayBadge;
    final discounted = deal.discountedPrice;
    final originalPrice = deal.productPrice;

    return Material(
      color: AppColors.ui.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Ink(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            boxShadow: AppEffects.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: Stack(
                  children: [
                    NetworkImageBox(
                      url: deal.ad.imageUrl ?? deal.productImageUrl ?? '',
                      height: 110,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: DiscountBadge(label: badge),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    if (originalPrice != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            Money.peso(discounted ?? originalPrice),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          if (discounted != null) ...[
                            const Gap(6),
                            Text(
                              Money.peso(originalPrice),
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.text.tertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    const Gap(6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.text.tertiary,
                        ),
                        const Gap(2),
                        Text(
                          '${deal.distanceKm.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.text.tertiary,
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
      ),
    );
  }
}
