import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/recommendations/domain/entities/nearby_deal.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/card_badges.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Opens the storefront a deal belongs to. Shared by the "Today's Deals"
/// rail and the Deals page so both navigate the same way.
void openDealStore(BuildContext context, NearbyDeal deal) => context.push(
  RouteNames.storefront,
  extra: StoreEntity(
    id: deal.storeId,
    name: deal.storeName,
    lat: 0,
    lng: 0,
    distance: deal.distanceKm,
  ),
);

/// A promotional deal card for the horizontal "Today's Deals" rail.
class DealCard extends StatelessWidget {
  const DealCard({
    required this.deal,
    this.onTap,
    this.width = 200,
    super.key,
  });

  final NearbyDeal deal;
  final VoidCallback? onTap;

  /// 200 in the rail; `double.infinity` to fill a grid cell.
  final double width;

  /// Height a deal card is laid out at, in the rail and the Deals grid.
  static const height = 252.0;

  static const _imageHeight = 110.0;
  static const _topRadius = BorderRadius.vertical(
    top: Radius.circular(AppRadius.card),
  );

  @override
  Widget build(BuildContext context) {
    final badge = deal.ad.displayBadge;
    final discounted = deal.discountedPrice;
    final originalPrice = deal.productPrice;
    final imageUrl = deal.ad.imageUrl ?? deal.productImageUrl;
    final endsAt = deal.endsAt;
    final title = deal.ad.title.trim().isNotEmpty
        ? deal.ad.title
        : (deal.productName ?? deal.storeName);

    return Material(
      color: AppColors.ui.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Ink(
          width: width,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _imageHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      if (imageUrl != null)
                        NetworkImageBox(
                          url: imageUrl,
                          height: _imageHeight,
                          borderRadius: _topRadius,
                          placeholderColor: AppColors.ui.surfaceMutedCool,
                        )
                      else
                        _FallbackCover(storeId: deal.storeId),
                      if (badge != null)
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          child: DiscountBadge(label: badge),
                        ),
                      if (endsAt != null)
                        Positioned(
                          right: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: _EndsIn(endsAt: endsAt),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        deal.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.secondary,
                        ),
                      ),
                      const Gap(6),
                      if (originalPrice != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            // Both prices may shrink in a narrow grid cell;
                            // the price paid keeps the larger share.
                            Flexible(
                              flex: 3,
                              child: Text(
                                Money.peso(discounted ?? originalPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (discounted != null) ...[
                              const Gap(6),
                              Flexible(
                                flex: 2,
                                child: Text(
                                  Money.peso(originalPrice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.text.secondary,
                                  ),
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
                            color: AppColors.text.secondary,
                          ),
                          const Gap(2),
                          Flexible(
                            child: Text(
                              '${deal.distanceKm.toStringAsFixed(1)} km away',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.text.secondary,
                              ),
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
      ),
    );
  }
}

/// Tinted cover with a storefront tile, shown when a deal has no image.
class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    final color = colorForKey(storeId);
    return Container(
      height: DealCard._imageHeight,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: DealCard._topRadius,
      ),
      child: IconTile(icon: Icons.storefront_rounded, color: color),
    );
  }
}

/// "Ends in HH:MM" chip for a deal that expires within the next day. Ticks
/// once a minute and hides itself once the deal has ended.
class _EndsIn extends StatefulWidget {
  const _EndsIn({required this.endsAt});

  final DateTime endsAt;

  @override
  State<_EndsIn> createState() => _EndsInState();
}

class _EndsInState extends State<_EndsIn> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    if (left.isNegative || left >= const Duration(days: 1)) {
      return const SizedBox.shrink();
    }
    final hh = left.inHours.toString().padLeft(2, '0');
    final mm = (left.inMinutes % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        borderRadius: AppRadius.brPill,
        boxShadow: AppEffects.overlayShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: AppColors.status.error),
          const Gap(4),
          Text(
            'Ends in $hh:$mm',
            style: TextStyle(
              color: AppColors.text.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
