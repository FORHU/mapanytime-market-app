import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/store_clusterer.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_list_tile.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Lists a tapped [StoreCluster]'s member stores — shown for a count cluster
/// too tight to keep zooming into, and always for a building group (see
/// `MapboxStyleManager.onClusterTap`'s "zoom, then sheet" policy).
///
/// Deliberately the same `DraggableScrollableSheet` shape as
/// [StoreBottomSheet] rather than a second sheet language: same sizing
/// (0.6 / 0.4 / 0.92), surface, radius, shadow and pill handle.
class ClusterStoresSheet extends StatelessWidget {
  const ClusterStoresSheet({required this.cluster, this.onNavigate, super.key});

  final StoreCluster cluster;
  final void Function(StoreEntity store)? onNavigate;

  static Future<void> show(
    BuildContext context, {
    required StoreCluster cluster,
    void Function(StoreEntity store)? onNavigate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          ClusterStoresSheet(cluster: cluster, onNavigate: onNavigate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.ui.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          boxShadow: AppEffects.cardShadow,
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            // No stagger: this list can run to dozens of members, and the
            // sheet's own slide-in is enough motion for something this
            // frequent — an infrequent staged entrance is what staggering
            // is for, not "every cluster tap."
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.text.tertiary,
                    borderRadius: AppRadius.brPill,
                  ),
                ),
              ),
              Text(
                cluster.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Gap(AppSpacing.md),
              for (final store in cluster.stores) ...[
                StoreListTile(
                  store: store,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(
                      StoreBottomSheet.show(
                        context,
                        store,
                        onNavigate: onNavigate == null
                            ? null
                            : () => onNavigate!(store),
                      ),
                    );
                  },
                ),
                const Gap(AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
