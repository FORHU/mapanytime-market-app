import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_tag_widget.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class WorldMapUiOverlay extends StatelessWidget {
  const WorldMapUiOverlay({
    required this.storeScreenPositions,
    required this.selectedStoreId,
    required this.currentZoom,
    required this.stores,
    required this.onNavigate,
    super.key,
  });

  final Map<String, ScreenCoordinate> storeScreenPositions;
  final String? selectedStoreId;
  final double currentZoom;
  final List<StoreEntity> stores;
  final void Function(StoreEntity) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: storeScreenPositions.entries.map((entry) {
        final storeId = entry.key;
        final coord = entry.value;

        // UX Hybrid Rule: Show ribbon if it is selected,
        // OR if zoom >= 16 and stores < 20
        final isSelected = storeId == selectedStoreId;
        final showOptionalLabels =
            currentZoom >= 16 && storeScreenPositions.length < 20;

        if (!isSelected && !showOptionalLabels) {
          return const SizedBox.shrink();
        }

        final store = stores.where((s) => s.id == storeId).firstOrNull;
        if (store == null) return const SizedBox.shrink();

        // We use FractionalTranslation to perfectly center the tag
        // and anchor its bottom tip directly to the geographic point,
        // no matter how long the store name is.
        return Positioned(
          left: coord.x,
          top: coord.y,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -1),
            child: IgnorePointer(
              // Allow map dragging underneath
              child: StoreTagWidget(
                name: store.name,
                onTap: () => onNavigate(store),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
