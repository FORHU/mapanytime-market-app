import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/home/presentation/home_mock_data.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/deal_card.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/explore_fab.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/fade_slide_in.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/hero_banner.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/home_app_bar.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/nearby_store_card.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/quick_category_item.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/recommended_store_card.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Buyer Home (Discover) tab — a map-first marketplace landing screen.
///
/// Presentational only: static dummy data ([HomeMock]), no state management.
/// Every action routes to the live map for now.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

  void _openMap(BuildContext context) => context.go(RouteNames.worldMap);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ExploreFab(onTap: () => _openMap(context)),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xxxl,
          ),
          children: [
            // --- Top bar ---
            Padding(
              padding: _hPad,
              child: FadeSlideIn(
                child: HomeAppBar(
                  greeting: HomeMock.greeting,
                  name: HomeMock.userName,
                  location: HomeMock.location,
                  onProfile: () => context.go(RouteNames.profile),
                ),
              ),
            ),
            const Gap(AppSpacing.lg),

            // --- Hero ---
            Padding(
              padding: _hPad,
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: HeroBanner(
                  nearbyCount: HomeMock.nearbyCount,
                  openNowCount: HomeMock.openNowCount,
                  dealsCount: HomeMock.dealsCount,
                  onOpenMap: () => _openMap(context),
                  onBrowseCategories: () => _openMap(context),
                ),
              ),
            ),
            const Gap(AppSpacing.xl),

            // --- Quick categories ---
            _QuickCategories(onTap: () => _openMap(context)),
            const Gap(AppSpacing.xl),

            // --- Nearby merchants ---
            Padding(
              padding: _hPad,
              child: SectionTitle(
                title: 'Nearby Merchants',
                actionLabel: 'See all',
                onAction: () => _openMap(context),
              ),
            ),
            const Gap(AppSpacing.md),
            _NearbyRail(onTap: () => _openMap(context)),
            const Gap(AppSpacing.xl),

            // --- Today's deals ---
            Padding(
              padding: _hPad,
              child: SectionTitle(
                title: "Today's Deals",
                actionLabel: 'See all',
                onAction: () => _openMap(context),
              ),
            ),
            const Gap(AppSpacing.md),
            _DealsRail(onTap: () => _openMap(context)),
            const Gap(AppSpacing.xl),

            // --- Recommended stores ---
            Padding(
              padding: _hPad,
              child: SectionTitle(
                title: 'Recommended Stores',
                actionLabel: 'See all',
                onAction: () => _openMap(context),
              ),
            ),
            const Gap(AppSpacing.md),
            for (final store in HomeMock.recommended)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: RecommendedStoreCard(
                  store: store,
                  onTap: () => _openMap(context),
                  onVisit: () => _openMap(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickCategories extends StatelessWidget {
  const _QuickCategories({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: HomeMock.categories.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) {
          final c = HomeMock.categories[i];
          return QuickCategoryItem(
            label: c.label,
            icon: c.icon,
            color: c.color,
            onTap: onTap,
          );
        },
      ),
    );
  }
}

class _NearbyRail extends StatelessWidget {
  const _NearbyRail({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 278,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: HomeMock.nearby.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) => NearbyStoreCard(
          merchant: HomeMock.nearby[i],
          onTap: onTap,
          onVisit: onTap,
        ),
      ),
    );
  }
}

class _DealsRail extends StatelessWidget {
  const _DealsRail({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: HomeMock.deals.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) => DealCard(
          deal: HomeMock.deals[i],
          onTap: onTap,
        ),
      ),
    );
  }
}
