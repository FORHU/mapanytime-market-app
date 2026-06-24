import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
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
  // Default to the safe 2D style. We will upgrade to 3D if the device is powerful.
  String _mapStyle = 'mapbox://styles/mapbox/streets-v12';

  @override
  void initState() {
    super.initState();
    unawaited(_checkDeviceCapabilities());
  }

  Future<void> _checkDeviceCapabilities() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        // If it's NOT a low RAM device, AND it's a modern Android version (Android 11+ / API 30+),
        // we can safely upgrade to the 3D Mapbox Standard style.
        if (!androidInfo.isLowRamDevice && androidInfo.version.sdkInt >= 30) {
          setState(() {
            _mapStyle = MapboxStyles.STANDARD;
          });
        }
      } catch (e) {
        debugPrint('Could not check device info: $e');
      }
    } else if (Platform.isIOS) {
      // iOS devices generally handle the 3D map fine.
      setState(() {
        _mapStyle = MapboxStyles.STANDARD;
      });
    }
  }

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

      try {
        final position = await geo.Geolocator.getCurrentPosition();
        await mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 14.0,
          ),
        );
      } catch (e) {
        debugPrint('Could not fetch location: $e');
      }
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
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            textureView: true,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          storesState.error is StoreLoadException
                              ? (storesState.error as StoreLoadException)
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
