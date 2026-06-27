import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart';

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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: storesState.maybeWhen(
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(
              child: Text(
                'No stores found near you.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 100,
            ), // Padding for fab
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.red.shade100,
                    child: const Icon(Icons.storefront, color: Colors.red),
                  ),
                  title: Text(
                    store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${store.distance.toStringAsFixed(2)} km away',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    unawaited(
                      StoreBottomSheet.show(
                        context,
                        store,
                        onNavigate: () => onNavigate(store),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        orElse: () =>
            const SizedBox.shrink(), // Status overlay handles loading/error
      ),
    );
  }
}
