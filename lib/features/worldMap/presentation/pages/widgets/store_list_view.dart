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

class StoreListView extends ConsumerStatefulWidget {
  const StoreListView({
    required this.onNavigate,
    super.key,
  });

  final void Function(StoreEntity store) onNavigate;

  @override
  ConsumerState<StoreListView> createState() => _StoreListViewState();
}

class _StoreListViewState extends ConsumerState<StoreListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load the next page as we approach the bottom of the list.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      unawaited(ref.read(worldMapControllerProvider.notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final storesState = ref.watch(worldMapControllerProvider);

    return ColoredBox(
      color: AppColors.ui.backgroundDark,
      child: storesState.maybeWhen(
        data: (data) {
          final stores = data.stores;
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
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100, // room for the FAB
            ),
            // One extra row for the trailing "loading more" indicator.
            itemCount: stores.length + (data.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index >= stores.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final store = stores[index];
              return GlassCard(
                onTap: () => unawaited(
                  StoreBottomSheet.show(
                    context,
                    store,
                    onNavigate: () => widget.onNavigate(store),
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
