import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
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
  // Default to the safe 2D streets style.
  String _mapStyle = 'mapbox://styles/mapbox/streets-v12';

  // We map Annotation IDs to the Store ID to prevent name-collision bugs
  final Map<String, String> _storeIdByAnnotationId = {};
  bool _is3DMode = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggle3DMode() {
    setState(() {
      _is3DMode = !_is3DMode;
    });
    unawaited(
      mapboxMap?.setCamera(
        CameraOptions(
          pitch: _is3DMode ? 60.0 : 0.0,
        ),
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    try {
      this.mapboxMap = mapboxMap;
      pointAnnotationManager = await mapboxMap.annotations
          .createPointAnnotationManager();
      if (!mounted) return;

      // The listener is deprecated but currently the only way to tap pins.
      // ignore: deprecated_member_use
      pointAnnotationManager?.addOnPointAnnotationClickListener(
        _PointAnnotationClickListener(context, ref, _storeIdByAnnotationId),
      );
      
      await _renderMarkers();
      await _enableUserLocation();
    } on Exception catch (e) {
      debugPrint('Mapbox initialization failed: $e');
    }
  }

  Future<void> _enableUserLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted && mapboxMap != null) {
      // Disabled Location Puck rendering here because it causes SIGSEGV Native
      // Crashes on older PowerVR GPUs (like Realme C11).
      // The camera will still center on the GPS location below!

      try {
        final position = await geo.Geolocator.getCurrentPosition();
        await mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 14,
          ),
        );
      } on Exception catch (e) {
        debugPrint('Could not fetch location: $e');
      }
    }
  }

  Future<void> _renderMarkers() async {
    final manager = pointAnnotationManager;
    if (manager == null) return;

    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];

    _storeIdByAnnotationId.clear();
    await manager.deleteAll();
    if (stores.isEmpty) return;

    final options = stores
        .map(
          (store) => PointAnnotationOptions(
            geometry: Point(coordinates: Position(store.lng, store.lat)),
            textField: store.name,
          ),
        )
        .toList();

    final createdAnnotations = await manager.createMulti(options);
    
    // Map the generated annotation IDs safely back to the actual Store IDs
    for (var i = 0; i < createdAnnotations.length; i++) {
      final annotation = createdAnnotations[i];
      if (annotation != null) {
        _storeIdByAnnotationId[annotation.id] = stores[i].id;
      }
    }
  }

  @override
  void dispose() {
    unawaited(pointAnnotationManager?.deleteAll());
    pointAnnotationManager = null;
    mapboxMap = null;
    super.dispose();
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
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            styleUri: _mapStyle,
            onMapCreated: _onMapCreated,
          ),
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
          Positioned(
            bottom: 32,
            right: 16,
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      _is3DMode ? Icons.threed_rotation : Icons.map,
                      color: Colors.black87,
                    ),
                    onPressed: _toggle3DMode,
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.layers, color: Colors.black87),
                  ),
                onSelected: (style) {
                  setState(() {
                    _mapStyle = style;
                  });
                  // Load style and re-render markers securely
                  unawaited(
                    mapboxMap?.loadStyleURI(style).then((_) {
                      unawaited(_renderMarkers());
                    }),
                  );
                },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'mapbox://styles/mapbox/streets-v12',
                  child: Text('Streets'),
                ),
                const PopupMenuItem<String>(
                  value: 'mapbox://styles/mapbox/satellite-streets-v12',
                  child: Text('Satellite Streets'),
                ),
                const PopupMenuItem<String>(
                  value: 'mapbox://styles/mapbox/dark-v11',
                  child: Text('Dark Mode'),
                ),
                const PopupMenuItem<String>(
                  value: 'mapbox://styles/mapbox/light-v11',
                  child: Text('Light Mode'),
                ),
              ],
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

/// Opens the store bottom sheet when a map pin is tapped. The mapbox plugin
/// only offers this listener through a deprecated interface for now.
// ignore: deprecated_member_use
class _PointAnnotationClickListener implements OnPointAnnotationClickListener {
  _PointAnnotationClickListener(this.context, this.ref, this.storeIdMap);

  final BuildContext context;
  final WidgetRef ref;
  final Map<String, String> storeIdMap;

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    
    final targetStoreId = storeIdMap[annotation.id];
    if (targetStoreId == null) return false;

    final store = stores.where((s) => s.id == targetStoreId).firstOrNull;
    if (store == null) return false;

    StoreBottomSheet.show(context, store);
    return true;
  }
}
