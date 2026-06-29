import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class WorldMapStatusOverlay extends ConsumerWidget {
  const WorldMapStatusOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesState = ref.watch(worldMapControllerProvider);

    return Stack(
      children: [
        if (storesState.isLoading && !storesState.hasValue)
          const Center(child: CircularProgressIndicator()),
        if (storesState.hasError && !storesState.isLoading)
          Positioned(
            bottom: 24,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: GlassCard(
              blur: true,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.status.error,
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      storesState.error is StoreLoadException
                          ? (storesState.error! as StoreLoadException)
                                .failure
                                .message
                          : storesState.error.toString(),
                      style: TextStyle(color: AppColors.text.secondaryDark),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(worldMapControllerProvider.notifier)
                        .refresh(),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.brand.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
