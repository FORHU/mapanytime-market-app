import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/recommendations/domain/entities/nearby_deal.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/promo_banner_card.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Home's promo/deals carousel — real merchant-ad data from the same feed
/// the "For You" page uses ([recommendationsFeedProvider]). Renders nothing
/// while loading, on error, or when there are no active deals nearby; no
/// placeholder marketing copy stands in for real curation.
class DealsCarousel extends ConsumerWidget {
  const DealsCarousel({super.key});

  void _openDeal(BuildContext context, NearbyDeal deal) => context.push(
    RouteNames.storefront,
    extra: StoreEntity(
      id: deal.storeId,
      name: deal.storeName,
      lat: 0,
      lng: 0,
      distance: deal.distanceKm,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals =
        ref.watch(recommendationsFeedProvider).value?.deals ?? const [];
    if (deals.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: deals.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) {
          final deal = deals[i];
          return SizedBox(
            width: MediaQuery.sizeOf(context).width - AppSpacing.xl,
            child: PromoBannerCard(
              imageUrl: deal.ad.imageUrl ?? deal.productImageUrl ?? '',
              title: deal.ad.title,
              subtitle: deal.storeName,
              ctaLabel: deal.ad.ctaLabel ?? 'Shop deal',
              onTap: () => _openDeal(context, deal),
            ),
          );
        },
      ),
    );
  }
}
