import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_list_view.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_tag_widget.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_floating_controls.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_status_overlay.dart';
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
  bool _showListView = false;

  // Custom GPS Tracker variables
  StreamSubscription<geo.Position>? _positionStreamSubscription;
  PolylineAnnotationManager? polylineAnnotationManager;
  PolylineAnnotation? _currentRoute;
  CircleAnnotationManager? circleAnnotationManager; // For User GPS
  CircleAnnotationManager? storeCircleAnnotationManager; // For Stores
  CircleAnnotation? _userLocationAnnotation;

  // Custom Flutter Overlay State
  final Map<String, ScreenCoordinate> _storeScreenPositions = {};
  
  // API Debouncer
  Timer? _debounceTimer;
  bool _isCameraMoving = false;

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

  Future<void> _startNavigationTo(StoreEntity store) async {
    if (_userLocationAnnotation == null || polylineAnnotationManager == null) {
      return;
    }

    final userPoint = _userLocationAnnotation!.geometry;
    final storePoint = Point(coordinates: Position(store.lng, store.lat));

    // Clear old route
    if (_currentRoute != null) {
      await polylineAnnotationManager!.delete(_currentRoute!);
    }

    // Draw simple straight line route
    _currentRoute = await polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: [
            userPoint.coordinates,
            storePoint.coordinates,
          ],
        ),
        lineColor: Colors.blue.toARGB32(),
        lineWidth: 5,
      ),
    );

    // Enter Navigation Guide Mode
    setState(() {
      _is3DMode = true;
    });

    await mapboxMap?.setCamera(
      CameraOptions(
        center: userPoint,
        zoom: 16, // Zoom in tight
        pitch: 60, // Tilt camera
        bearing: 0, // Face North (could calculate actual bearing here)
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    try {
      this.mapboxMap = mapboxMap;
      pointAnnotationManager = await mapboxMap.annotations
          .createPointAnnotationManager();
      polylineAnnotationManager = await mapboxMap.annotations
          .createPolylineAnnotationManager();
      circleAnnotationManager = await mapboxMap.annotations
          .createCircleAnnotationManager();
      storeCircleAnnotationManager = await mapboxMap.annotations
          .createCircleAnnotationManager();

      // Hide all default Mapbox businesses, restaurants, and transit stops
      try {
        final layers = await mapboxMap.style.getStyleLayers();
        for (final layer in layers) {
          if (layer == null) continue;
          final id = layer.id.toLowerCase();
          // Hide points of interest and transit labels
          if (id.contains('poi') || id.contains('transit')) {
            await mapboxMap.style.setStyleLayerProperty(
              layer.id,
              'visibility',
              'none',
            );
          }
        }
      } on Exception catch (e) {
        debugPrint('Note: Some POI layers could not be hidden: $e');
      }

      if (!mounted) return;

      // The listener is deprecated but currently the only way to tap pins.
      // ignore: deprecated_member_use
      pointAnnotationManager?.addOnPointAnnotationClickListener(
        _PointAnnotationClickListener(
          context,
          ref,
          _storeIdByAnnotationId,
          _startNavigationTo,
        ),
      );

      await _renderMarkers();
      await _enableUserLocation();
    } on Exception catch (e) {
      debugPrint('Mapbox initialization failed: $e');
    }
  }

  // ... (rest remains unchanged)
  Future<void> _enableUserLocation() async {
    final status = await Permission.locationWhenInUse.request();
    
    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text(
            'We need your location to show stores near you. '
            'Please enable location permissions in your settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(openAppSettings());
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    if (status.isGranted && mapboxMap != null) {
      // Disabled Native Location Puck because it causes GPU SIGSEGV crashes
      // on some devices.
      try {
        final initialPos = await geo.Geolocator.getCurrentPosition();
        await mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(initialPos.longitude, initialPos.latitude),
            ),
            zoom: 14,
          ),
        );
        
        // Force an explicit fetch of stores around the user's initial location
        // since programmatic setCamera calls sometimes bypass the camera movement listener
        unawaited(_onCameraIdle());

        // Start listening to the custom GPS stream to draw our own tracker
        _positionStreamSubscription =
            geo.Geolocator.getPositionStream(
              locationSettings: const geo.LocationSettings(
                accuracy: geo.LocationAccuracy.high,
                distanceFilter: 2, // Update every 2 meters
              ),
            ).listen((currentPos) async {
              if (!mounted || circleAnnotationManager == null) return;

              final pos = Position(currentPos.longitude, currentPos.latitude);

              if (_userLocationAnnotation == null) {
                // Create a safe, hardware-accelerated vector circle instead of text/images
                _userLocationAnnotation = await circleAnnotationManager!.create(
                  CircleAnnotationOptions(
                    geometry: Point(coordinates: pos),
                    circleColor: Colors.blue.toARGB32(),
                    circleRadius: 10,
                    circleStrokeColor: Colors.white.toARGB32(),
                    circleStrokeWidth: 3,
                  ),
                );
              } else {
                // Update the existing marker's position
                _userLocationAnnotation!.geometry = Point(coordinates: pos);
                await circleAnnotationManager!.update(_userLocationAnnotation!);
              }
            });
      } on Exception catch (e) {
        debugPrint('Could not fetch location: $e');
      }
    }
  }

  Future<void> _renderMarkers() async {
    final manager =
        storeCircleAnnotationManager; // Use dedicated store manager!
    if (manager == null || mapboxMap == null) return;

    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    if (stores.isEmpty) return;

    unawaited(manager.deleteAll()); // Only deletes stores now
    _storeIdByAnnotationId.clear();

    final options = stores
        .map(
          (store) => CircleAnnotationOptions(
            geometry: Point(coordinates: Position(store.lng, store.lat)),
            circleColor: Colors.red.toARGB32(), // Red dot for stores
            circleRadius: 12,
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 3,
          ),
        )
        .toList();

    if (options.isEmpty) return;
    try {
      debugPrint(
        'Attempting to render ${options.length} store markers as circles...',
      );
      final annotations = await manager.createMulti(options);
      debugPrint('Successfully created ${annotations.length} circle markers!');
      for (var i = 0; i < annotations.length; i++) {
        final annotation = annotations[i];
        if (annotation != null) {
          _storeIdByAnnotationId[annotation.id] = stores[i].id;
        }
      }
    } on Exception catch (e, stack) {
      debugPrint('Failed to create circle annotations: $e\n$stack');
    }

    // Trigger overlay update for the newly loaded stores
    unawaited(_updateStoreScreenPositions());
  }

  Future<void> _updateStoreScreenPositions({int retries = 3}) async {
    if (mapboxMap == null || _showListView) return;
    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    if (stores.isEmpty) return;

    debugPrint('Calculating screen positions for ${stores.length} stores...');
    final newPositions = <String, ScreenCoordinate>{};
    var hadError = false;

    for (final store in stores) {
      try {
        final screenCoord = await mapboxMap!.pixelForCoordinate(
          Point(coordinates: Position(store.lng, store.lat)),
        );
        newPositions[store.id] = screenCoord;
      } on Exception catch (_) {
        hadError = true;
      }
    }

    if (mounted) {
      setState(() {
        _storeScreenPositions
          ..clear()
          ..addAll(newPositions);
      });
    }

    // If Mapbox native renderer wasn't ready, it throws. We retry a few times.
    if (hadError && retries > 0) {
      unawaited(
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            unawaited(_updateStoreScreenPositions(retries: retries - 1));
          }
        }),
      );
    }
  }

  Future<void> _onCameraIdle() async {
    if (mapboxMap == null) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() {
        _isCameraMoving = false;
      });
      
      try {
        final cameraState = await mapboxMap!.getCameraState();
        final center = cameraState.center;
        
        // Only fetch if we are relatively zoomed in
        if (cameraState.zoom < 8) return; 

        // Dynamic radius: at zoom 14, ~5km. At zoom 10, ~50km.
        final radius = 50.0 / (cameraState.zoom / 10.0);
        final notifier = ref.read(worldMapControllerProvider.notifier);
        await notifier.fetchStoresAtLocation(
          lat: center.coordinates.lat.toDouble(),
          lng: center.coordinates.lng.toDouble(),
          radius: radius,
        );
      } on Exception catch (e) {
        debugPrint('Failed to get camera state for debounced fetch: $e');
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    
    final cancelSub = _positionStreamSubscription?.cancel();
    if (cancelSub != null) unawaited(cancelSub);

    final cancelPoints = pointAnnotationManager?.deleteAll();
    if (cancelPoints != null) unawaited(cancelPoints);

    final cancelStores =
        storeCircleAnnotationManager?.deleteAll();
    if (cancelStores != null) unawaited(cancelStores);
    
    pointAnnotationManager = null;
    storeCircleAnnotationManager = null;
    mapboxMap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-render pins whenever the store list changes (e.g. after a refresh).
    ref.listen(worldMapControllerProvider, (previous, next) {
      unawaited(_renderMarkers());
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.worldMap)),
      body: Stack(
        children: [
          Offstage(
            offstage: _showListView,
            child: Stack(
              children: [
                MapWidget(
                  key: const ValueKey('mapWidget'),
                  styleUri: _mapStyle,
                  onMapCreated: _onMapCreated,
                  onCameraChangeListener: (_) {
                    if (!_isCameraMoving) {
                      setState(() {
                        _isCameraMoving = true;
                      });
                    }
                    unawaited(_updateStoreScreenPositions());
                    unawaited(_onCameraIdle());
                  },
                ),
                // Render the Custom Flutter Red Ribbon Tags over the Map!
                ..._storeScreenPositions.entries.map((entry) {
                  final storeId = entry.key;
                  final coord = entry.value;
                  final store =
                      (ref.read(worldMapControllerProvider).valueOrNull ?? [])
                          .where((s) => s.id == storeId)
                          .firstOrNull;

                  if (store == null) return const SizedBox.shrink();

                  // We use FractionalTranslation to perfectly center the tag horizontally
                  // and anchor its bottom tip directly to the geographic point,
                  // regardless of how wide the store name text is!
                  return Positioned(
                    left: coord.x,
                    top: coord.y,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -1.0),
                      child: AnimatedOpacity(
                        opacity: _isCameraMoving ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: StoreTagWidget(
                          name: store.name,
                          onTap: () {
                            StoreBottomSheet.show(
                              context,
                              store,
                              onNavigate: () => {},
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          if (_showListView)
            StoreListView(
              onNavigate: (store) {
                // Handle navigation inside list view
              },
            ),
          const WorldMapStatusOverlay(),
          WorldMapFloatingControls(
            is3DMode: _is3DMode,
            isListView: _showListView,
            onToggleListView: () {
              setState(() {
                _showListView = !_showListView;
              });
            },
            onToggle3DMode: _toggle3DMode,
            onStyleSelected: (style) {
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
  _PointAnnotationClickListener(
    this.context,
    this.ref,
    this.storeIdMap,
    this.onNavigate,
  );

  final BuildContext context;
  final WidgetRef ref;
  final Map<String, String> storeIdMap;
  final void Function(StoreEntity store) onNavigate;

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];

    final targetStoreId = storeIdMap[annotation.id];
    if (targetStoreId == null) return false;

    final store = stores.where((s) => s.id == targetStoreId).firstOrNull;
    if (store == null) return false;

    StoreBottomSheet.show(context, store, onNavigate: () => onNavigate(store));
    return true;
  }
}
