import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/recommendations/domain/entities/nearby_deal.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/deal_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/nearby_store_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/recommended_store_card.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// "For You" tab — nearby merchants, today's deals, and top-rated stores
/// near the buyer. Ranking is location/rating based, not per-user
/// personalization (see [recommendationsFeedProvider]).
class RecommendationsPage extends ConsumerWidget {
  const RecommendationsPage({super.key});

  void _openStore(BuildContext context, StoreEntity store) =>
      context.push(RouteNames.storefront, extra: store);

  void _openDeal(BuildContext context, NearbyDeal deal) => _openStore(
    context,
    StoreEntity(
      id: deal.storeId,
      name: deal.storeName,
      lat: 0,
      lng: 0,
      distance: deal.distanceKm,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(recommendationsFeedProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(recommendationsFeedProvider),
          child: feedAsync.when(
            loading: () => const _LoadingState(),
            error: (_, _) => _ErrorState(
              onRetry: () => ref.invalidate(recommendationsFeedProvider),
            ),
            data: (feed) => feed.isEmpty
                ? const _EmptyState()
                : _FeedList(
                    feed: feed,
                    onOpenStore: _openStore,
                    onOpenDeal: _openDeal,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.feed,
    required this.onOpenStore,
    required this.onOpenDeal,
  });

  final RecommendationsFeed feed;
  final void Function(BuildContext, StoreEntity) onOpenStore;
  final void Function(BuildContext, NearbyDeal) onOpenDeal;

  static const _hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Padding(
          padding: _hPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For You',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Gap(2),
              Text(
                'Nearby merchants and deals for you',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text.secondaryDark,
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.lg),

        if (feed.nearby.isNotEmpty) ...[
          const Padding(
            padding: _hPad,
            child: SectionTitle(title: 'Nearby Merchants'),
          ),
          const Gap(AppSpacing.md),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: feed.nearby.length.clamp(0, 10),
              separatorBuilder: (_, _) => const Gap(AppSpacing.md),
              itemBuilder: (context, i) {
                final store = feed.nearby[i];
                return NearbyStoreCard(
                  store: store,
                  onTap: () => onOpenStore(context, store),
                  onVisit: () => onOpenStore(context, store),
                );
              },
            ),
          ),
          const Gap(AppSpacing.xl),
        ],

        if (feed.deals.isNotEmpty) ...[
          const Padding(
            padding: _hPad,
            child: SectionTitle(title: "Today's Deals"),
          ),
          const Gap(AppSpacing.md),
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: feed.deals.length,
              separatorBuilder: (_, _) => const Gap(AppSpacing.md),
              itemBuilder: (context, i) {
                final deal = feed.deals[i];
                return DealCard(
                  deal: deal,
                  onTap: () => onOpenDeal(context, deal),
                );
              },
            ),
          ),
          const Gap(AppSpacing.xl),
        ],

        if (feed.recommended.isNotEmpty) ...[
          const Padding(
            padding: _hPad,
            child: SectionTitle(title: 'Recommended Stores'),
          ),
          const Gap(AppSpacing.md),
          for (final store in feed.recommended.take(10))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: RecommendedStoreCard(
                store: store,
                onTap: () => onOpenStore(context, store),
                onVisit: () => onOpenStore(context, store),
              ),
            ),
        ],
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [Gap(200), Center(child: CircularProgressIndicator())],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Gap(140),
        Center(
          child: Column(
            children: [
              Text(
                "Couldn't load your recommendations",
                style: TextStyle(color: AppColors.text.secondaryDark),
              ),
              const Gap(AppSpacing.md),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Gap(140),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              "We couldn't find anything nearby — check your location "
              'permission and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text.secondaryDark),
            ),
          ),
        ),
      ],
    );
  }
}
