// The Mapbox plugin uses some deprecated interfaces.
// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/mapbox_style_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/user_location_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/world_map_ui_overlay.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_list_view.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_floating_controls.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_status_overlay.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class WorldMapPage extends ConsumerStatefulWidget {
  const WorldMapPage({super.key});

  @override
  ConsumerState<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends ConsumerState<WorldMapPage> {
  MapboxMap? mapboxMap;
  
  // Managers
  late final UserLocationManager _locationManager;
  MapboxStyleManager? _styleManager;

  // Custom UI State
  final Map<String, ScreenCoordinate> _storeScreenPositions = {};
  String? _selectedStoreId;
  double _currentZoom = 14;
  bool _is3DMode = false;
  bool _showListView = false;
  bool _isCameraMoving = false;

  // Route State
  PolylineAnnotationManager? polylineAnnotationManager;
  PolylineAnnotation? _currentRoute;

  Timer? _debounceTimer;
  String _mapStyle = 'mapbox://styles/mapbox/streets-v12';

  @override
  void initState() {
    super.initState();
    _locationManager = UserLocationManager();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    _styleManager = MapboxStyleManager(mapboxMap);

    try {
      polylineAnnotationManager = await mapboxMap.annotations
          .createPolylineAnnotationManager();
      
      await _locationManager.initialize(mapboxMap);
      await _styleManager!.initializeClusters();
      await _styleManager!.hidePoiLayers();

      if (!mounted) return;

      await _renderMarkers();
      await _locationManager.enableUserLocation();
    } on Exception catch (e) {
      debugPrint('Error initializing map: $e');
    }
  }

  void _onMapTap(MapContentGestureContext tapContext) {
    unawaited(_handleMapTap(tapContext));
  }

  Future<void> _handleMapTap(MapContentGestureContext tapContext) async {
    if (mapboxMap == null) return;
    
    final point = tapContext.point;
    final screenPoint = tapContext.touchPosition;

    final screenBox = ScreenBox(
        min: ScreenCoordinate(x: screenPoint.x - 20, y: screenPoint.y - 20),
        max: ScreenCoordinate(x: screenPoint.x + 20, y: screenPoint.y + 20));

    final features = await mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(screenBox),
        RenderedQueryOptions(
            layerIds: ['clusters', 'unclustered-point']));

    if (features.isNotEmpty) {
      final firstFeature = features.first;
      if (firstFeature == null) return;
      
      final geoJsonFeature = firstFeature.queriedFeature.feature;
      final properties = geoJsonFeature['properties'] as Map?;
      
      if (properties != null) {
        final isCluster = properties['cluster'] == true;
        if (isCluster) {
          final currentCamera = await mapboxMap!.getCameraState();
          await mapboxMap!.setCamera(CameraOptions(
            center: point,
            zoom: currentCamera.zoom + 2,
          ));
        } else {
          final storeId = properties['storeId'] as String?;
          if (storeId != null) {
            _selectStore(storeId);
          }
        }
      }
    }
  }

  void _selectStore(String storeId) {
    if (mounted) {
      setState(() {
        _selectedStoreId = storeId;
      });
      unawaited(_updateStoreScreenPositions());
    }

    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    final store = stores.where((s) => s.id == storeId).firstOrNull;
    if (store != null) {
      unawaited(
        StoreBottomSheet.show(
          context,
          store,
          onNavigate: () => _startNavigationTo(store),
        ).whenComplete(() {
          if (mounted) {
            setState(() {
              _selectedStoreId = null;
            });
            unawaited(_updateStoreScreenPositions());
          }
        }),
      );
    }
  }

  Future<void> _renderMarkers() async {
    if (_styleManager == null) return;
    
    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    await _styleManager!.updateGeoJsonSource(stores);
    unawaited(_updateStoreScreenPositions());
  }

  Future<void> _updateStoreScreenPositions({int retries = 3}) async {
    if (mapboxMap == null) return;

    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    if (stores.isEmpty) {
      if (mounted) {
        setState(_storeScreenPositions.clear);
      }
      return;
    }

    try {
      final cameraState = await mapboxMap!.getCameraState();
      _currentZoom = cameraState.zoom;
      
      final points = stores
          .map((s) => Point(coordinates: Position(s.lng, s.lat)))
          .toList();
      final screenCoords = await mapboxMap!.pixelsForCoordinates(points);
      
      if (screenCoords.length == stores.length) {
        final newPositions = <String, ScreenCoordinate>{};
        for (var i = 0; i < stores.length; i++) {
          newPositions[stores[i].id] = screenCoords[i]!;
        }
        
        if (mounted) {
          setState(() {
            _storeScreenPositions
              ..clear()
              ..addAll(newPositions);
          });
        }
      }
    } on Exception catch (e) {
      debugPrint('Failed to update screen positions: $e');
      if (retries > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await _updateStoreScreenPositions(retries: retries - 1);
      }
    }
  }

  Future<void> _onCameraIdle() async {
    if (mapboxMap == null || !mounted) return;

    setState(() {
      _isCameraMoving = false;
    });

    final cameraState = await mapboxMap!.getCameraState();
    final center = cameraState.center;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final lat = center.coordinates.lat.toDouble();
      final lng = center.coordinates.lng.toDouble();
      unawaited(
        ref.read(worldMapControllerProvider.notifier).fetchStoresAtLocation(
              north: lat + 0.05,
              south: lat - 0.05,
              east: lng + 0.05,
              west: lng - 0.05,
            )
      );
      unawaited(_updateStoreScreenPositions());
    });
  }

  void _toggle3DMode() {
    setState(() {
      _is3DMode = !_is3DMode;
    });
    unawaited(
      mapboxMap?.setCamera(
        CameraOptions(
          pitch: _is3DMode ? 60 : 0,
        ),
      ),
    );
  }

  Future<void> _startNavigationTo(StoreEntity store) async {
    final userPoint = _locationManager.getUserLocation();
    if (userPoint == null || polylineAnnotationManager == null) return;

    final storePoint = Point(coordinates: Position(store.lng, store.lat));

    if (_currentRoute != null) {
      await polylineAnnotationManager!.delete(_currentRoute!);
    }

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

    setState(() {
      _is3DMode = true;
    });

    unawaited(
      mapboxMap?.setCamera(
        CameraOptions(
          center: userPoint,
          zoom: 18,
          pitch: 60,
          bearing: 0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    
    final cancelRoute = polylineAnnotationManager?.deleteAll();
    if (cancelRoute != null) unawaited(cancelRoute);
    
    unawaited(_locationManager.dispose());

    polylineAnnotationManager = null;
    mapboxMap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(worldMapControllerProvider, (previous, next) {
      unawaited(_renderMarkers());
    });

    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];

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
                  onTapListener: _onMapTap,
                  onCameraChangeListener: (_) {
                    if (!_isCameraMoving) {
                      setState(() {
                        _isCameraMoving = true;
                      });
                    }
                    unawaited(_onCameraIdle());
                  },
                ),
                
                WorldMapUiOverlay(
                  storeScreenPositions: _storeScreenPositions,
                  selectedStoreId: _selectedStoreId,
                  currentZoom: _currentZoom,
                  stores: stores,
                  onNavigate: _startNavigationTo,
                ),

                const Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: WorldMapStatusOverlay(),
                ),

                Positioned(
                  bottom: 16,
                  right: 16,
                  child: WorldMapFloatingControls(
                    is3DMode: _is3DMode,
                    isListView: _showListView,
                    onToggle3DMode: _toggle3DMode,
                    onToggleListView: () {
                      setState(() {
                        _showListView = !_showListView;
                      });
                    },
                    onStyleSelected: (style) {
                      setState(() {
                        _mapStyle = style;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showListView) StoreListView(onNavigate: _startNavigationTo),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _showListView = !_showListView;
          });
        },
        icon: Icon(_showListView ? Icons.map : Icons.list),
        label: Text(_showListView ? 'View Map' : 'View List'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
