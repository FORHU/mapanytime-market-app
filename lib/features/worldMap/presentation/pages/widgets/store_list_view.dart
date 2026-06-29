import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class StoreListView extends ConsumerWidget {
  const StoreListView({
    required this.onNavigate,
    super.key,
  });

  final void Function(StoreEntity store) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesState = ref.watch(worldMapControllerProvider);

    return ColoredBox(
      color: AppColors.ui.backgroundDark,
      child: storesState.maybeWhen(
        data: (stores) {
          if (stores.isEmpty) {
            return Center(
              child: Text(
                'No stores found near you.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.text.tertiaryDark,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100, // room for the FAB
            ),
            itemCount: stores.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (context, index) {
              final store = stores[index];
              return GlassCard(
                onTap: () => unawaited(
                  StoreBottomSheet.show(
                    context,
                    store,
                    onNavigate: () => onNavigate(store),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brand.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: AppColors.brand.primary,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            '${store.distance.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.text.tertiaryDark,
                    ),
                  ],
                ),
              );
            },
          );
        },
        orElse: SizedBox.shrink,
      ),
    );
  }
}
