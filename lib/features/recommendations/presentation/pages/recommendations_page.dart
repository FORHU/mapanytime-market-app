import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/extensions.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/deal_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/feed_placeholders.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/nearby_store_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/recommended_store_card.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// "For You" tab — nearby merchants, today's deals, and top-rated stores
/// near the buyer. Ranking is location/rating based, not per-user
/// personalization (see [recommendationsFeedProvider]).
class RecommendationsPage extends ConsumerWidget {
  const RecommendationsPage({super.key});

  void _openStore(BuildContext context, StoreEntity store) =>
      context.push(RouteNames.storefront, extra: store);

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
                    onRetryDeals: () =>
                        ref.invalidate(recommendationsFeedProvider),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({
    required this.feed,
    required this.onOpenStore,
    required this.onRetryDeals,
  });

  final RecommendationsFeed feed;
  final void Function(BuildContext, StoreEntity) onOpenStore;
  final VoidCallback onRetryDeals;

  static const _hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

  /// Space under horizontal rails so the cards' lifted shadow isn't clipped
  /// by the list viewport. Added to each rail's height so cards keep theirs.
  static const _railShadowRoom = 14.0;
  static const nearbyCardHeight = 314.0;
  static const _railPad = EdgeInsets.fromLTRB(
    AppSpacing.md,
    0,
    AppSpacing.md,
    _railShadowRoom,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedStoreIds = ref.watch(savedStoreIdsProvider);

    Future<void> toggleSaved(StoreEntity store) async {
      final ok = await ref
          .read(savedStoresControllerProvider.notifier)
          .toggle(store);
      if (!ok && context.mounted) {
        context.showSnackBar("Couldn't update Saved — try again");
      }
    }

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
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const Gap(2),
              Text(
                'Nearby merchants and deals for you',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text.secondary,
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.lg),

        if (feed.nearby.isNotEmpty) ...[
          const Padding(
            padding: _hPad,
            child: _SectionHeading('Nearby Merchants'),
          ),
          const Gap(AppSpacing.md),
          SizedBox(
            height: nearbyCardHeight + _railShadowRoom,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: _railPad,
              itemCount: feed.nearby.length.clamp(0, 10),
              separatorBuilder: (_, _) => const Gap(AppSpacing.md),
              itemBuilder: (context, i) {
                final store = feed.nearby[i];
                return NearbyStoreCard(
                  store: store,
                  // No card-level tap: only Visit Store navigates, and the
                  // heart only saves/unsaves.
                  isFavorite: savedStoreIds.contains(store.id),
                  onFavorite: () => toggleSaved(store),
                  onVisit: () => onOpenStore(context, store),
                );
              },
            ),
          ),
          const Gap(AppSpacing.xl),
        ],

        // Always shown, so buyers can tell "no deals" apart from a missing
        // section.
        Padding(
          padding: _hPad,
          child: _SectionHeading(
            "Today's Deals",
            onSeeAll: feed.deals.isEmpty
                ? null
                : () => context.push(RouteNames.deals),
          ),
        ),
        const Gap(AppSpacing.md),
        if (feed.dealsFailed)
          Padding(
            padding: _hPad,
            child: DealsNotice.failed(onRetry: onRetryDeals),
          )
        else if (feed.deals.isEmpty)
          const Padding(padding: _hPad, child: DealsNotice.empty())
        else
          SizedBox(
            height: DealCard.height + _railShadowRoom,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: _railPad,
              itemCount: feed.deals.length,
              separatorBuilder: (_, _) => const Gap(AppSpacing.md),
              itemBuilder: (context, i) {
                final deal = feed.deals[i];
                return DealCard(
                  deal: deal,
                  onTap: () => openDealStore(context, deal),
                );
              },
            ),
          ),
        const Gap(AppSpacing.xl),

        if (feed.recommended.isNotEmpty) ...[
          const Padding(
            padding: _hPad,
            child: _SectionHeading('Recommended Stores'),
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
                onVisit: () => onOpenStore(context, store),
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.onSeeAll});

  final String title;

  /// Shows a trailing "See all" action when set.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 19,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              visualDensity: VisualDensity.compact,
              textStyle: theme.textTheme.labelLarge,
            ),
            child: const Text('See all'),
          ),
      ],
    );
  }
}

/// First-load skeleton mirroring the feed: title, a Nearby rail, a Deals
/// rail and a couple of Recommended rows.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    const hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

    Widget rail(double width, double height) => SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: hPad,
        itemCount: 3,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (_, _) => SkeletonBox(
          width: width,
          height: height,
          radius: AppRadius.card,
        ),
      ),
    );

    return SkeletonPulse(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        children: [
          const Padding(
            padding: hPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 32),
                Gap(6),
                SkeletonBox(width: 210, height: 14),
              ],
            ),
          ),
          const Gap(AppSpacing.lg),
          const Padding(
            padding: hPad,
            child: SkeletonBox(width: 180, height: 22),
          ),
          const Gap(AppSpacing.md),
          rail(260, _FeedList.nearbyCardHeight),
          const Gap(AppSpacing.xl),
          const Padding(
            padding: hPad,
            child: SkeletonBox(width: 150, height: 22),
          ),
          const Gap(AppSpacing.md),
          rail(200, DealCard.height),
          const Gap(AppSpacing.xl),
          for (var i = 0; i < 2; i++)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: SkeletonBox(height: 100, radius: AppRadius.card),
            ),
        ],
      ),
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
                style: TextStyle(color: AppColors.text.secondary),
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
              style: TextStyle(color: AppColors.text.secondary),
            ),
          ),
        ),
      ],
    );
  }
}
