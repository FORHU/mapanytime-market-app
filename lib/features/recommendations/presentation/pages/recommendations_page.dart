import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/recommendations_mock_data.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/deal_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/nearby_store_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/recommended_store_card.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// "For You" tab — personalised picks: nearby merchants, today's deals and
/// recommended stores. Presentational only ([RecommendationsMock]); every
/// action routes to the live map for now.
class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  static const _hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

  void _openMap(BuildContext context) => context.go(RouteNames.worldMap);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xxxl,
          ),
          children: [
            // --- Header ---
            Padding(
              padding: _hPad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For You',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Gap(2),
                  Text(
                    'Personalised picks near you',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),

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
            for (final store in RecommendationsMock.recommended)
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

class _NearbyRail extends StatelessWidget {
  const _NearbyRail({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: RecommendationsMock.nearby.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) => NearbyStoreCard(
          merchant: RecommendationsMock.nearby[i],
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
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: RecommendationsMock.deals.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) =>
            DealCard(deal: RecommendationsMock.deals[i], onTap: onTap),
      ),
    );
  }
}
