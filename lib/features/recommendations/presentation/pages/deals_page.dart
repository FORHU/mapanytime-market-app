import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/deal_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/feed_placeholders.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// "See all" for the For You page's "Today's Deals" rail — the same nearby
/// deals ([recommendationsFeedProvider], already cached) as a 2-column grid.
class DealsPage extends ConsumerWidget {
  const DealsPage({super.key});

  static const _grid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: AppSpacing.md,
    crossAxisSpacing: 12,
    mainAxisExtent: DealCard.height,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(recommendationsFeedProvider);
    void retry() => ref.invalidate(recommendationsFeedProvider);
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
    );

    Widget notice(Widget child) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [child],
    );

    return Scaffold(
      appBar: const ModernAppBar(title: "Today's Deals"),
      body: RefreshIndicator(
        onRefresh: () async => retry(),
        child: feedAsync.when(
          loading: () => SkeletonPulse(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: padding,
              gridDelegate: _grid,
              itemCount: 6,
              itemBuilder: (_, _) => const SkeletonBox(radius: AppRadius.card),
            ),
          ),
          error: (_, _) => notice(DealsNotice.failed(onRetry: retry)),
          data: (feed) {
            if (feed.dealsFailed) {
              return notice(DealsNotice.failed(onRetry: retry));
            }
            if (feed.deals.isEmpty) return notice(const DealsNotice.empty());
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              gridDelegate: _grid,
              itemCount: feed.deals.length,
              itemBuilder: (context, i) {
                final deal = feed.deals[i];
                return DealCard(
                  deal: deal,
                  width: double.infinity,
                  onTap: () => openDealStore(context, deal),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
