import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class WorldMapPage extends ConsumerStatefulWidget {
  const WorldMapPage({super.key});

  @override
  ConsumerState<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends ConsumerState<WorldMapPage> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    if (!mounted) return;

    // The plugin only exposes the click listener via this deprecated setter;
    // there is no replacement API in the current mapbox_maps_flutter version.
    // ignore: deprecated_member_use
    pointAnnotationManager?.addOnPointAnnotationClickListener(
      _PointAnnotationClickListener(context, ref),
    );
    await _renderMarkers();
    await _enableUserLocation();
  }

  Future<void> _enableUserLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted && mapboxMap != null) {
      await mapboxMap!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,
        ),
      );

      // The puck will be displayed, but camera tracking in this Mapbox
      // version requires the 'geolocator' package to get the exact 
      // coordinates before manually setting the camera.
    }
  }

  Future<void> _renderMarkers() async {
    final manager = pointAnnotationManager;
    if (manager == null) return;

    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];

    await manager.deleteAll();
    if (stores.isEmpty) return;

    final annotations = stores
        .map(
          (store) => PointAnnotationOptions(
            geometry: Point(coordinates: Position(store.lng, store.lat)),
            textField: store.name,
          ),
        )
        .toList();

    await manager.createMulti(annotations);
  }

  @override
  Widget build(BuildContext context) {
    // Re-render pins whenever the store list changes (e.g. after a refresh).
    ref.listen(worldMapControllerProvider, (previous, next) {
      unawaited(_renderMarkers());
    });

    final storesState = ref.watch(worldMapControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.worldMap)),
      body: storesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MapError(
          message: error is StoreLoadException
              ? error.failure.message
              : error.toString(),
          onRetry: () =>
              ref.read(worldMapControllerProvider.notifier).refresh(),
        ),
        data: (_) => MapWidget(
          key: const ValueKey('mapWidget'),
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }
}

class _MapError extends StatelessWidget {
  const _MapError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Opens the store bottom sheet when a map pin is tapped. The mapbox plugin
/// only offers this listener through a deprecated interface for now.
// ignore: deprecated_member_use
class _PointAnnotationClickListener implements OnPointAnnotationClickListener {
  _PointAnnotationClickListener(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    final store = stores
        .where((s) => s.name == annotation.textField)
        .firstOrNull;
    if (store == null) return false;

    StoreBottomSheet.show(context, store);
    return true;
  }
}
