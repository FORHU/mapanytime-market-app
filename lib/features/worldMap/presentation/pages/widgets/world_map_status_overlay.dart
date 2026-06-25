import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';

class WorldMapStatusOverlay extends ConsumerWidget {
  const WorldMapStatusOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesState = ref.watch(worldMapControllerProvider);

    return Stack(
      children: [
        if (storesState.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (storesState.hasError && !storesState.isLoading)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Card(
              color: Colors.white.withValues(alpha: 0.9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        storesState.error is StoreLoadException
                            ? (storesState.error! as StoreLoadException)
                                  .failure
                                  .message
                            : storesState.error.toString(),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(worldMapControllerProvider.notifier)
                          .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
