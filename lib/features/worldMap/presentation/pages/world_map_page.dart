// The Mapbox plugin uses some deprecated interfaces.
// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/directions_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/mapbox_style_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/user_location_manager.dart';
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
  String? _selectedStoreId;
  bool _is3DMode = false;
  bool _showListView = false;

  // Route State
  PolylineAnnotationManager? polylineAnnotationManager;
  PolylineAnnotation? _currentRoute;
  final _directionsDatasource = DirectionsDatasource();

  Timer? _debounceTimer;
  String _mapStyle = 'mapbox://styles/mapbox/streets-v12';

  // Riverpod listener — registered once in initState, cancelled in dispose
  ProviderSubscription<AsyncValue<List<StoreEntity>>>? _storesSubscription;

  @override
  void initState() {
    super.initState();
    _locationManager = UserLocationManager();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register exactly once — re-renders markers whenever
    // the store list changes.
    _storesSubscription ??= ref.listenManual(
      worldMapControllerProvider,
      (previous, next) {
        unawaited(_renderMarkers());
      },
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    _styleManager = MapboxStyleManager(mapboxMap);

    try {
      polylineAnnotationManager =
          await mapboxMap.annotations.createPolylineAnnotationManager();

      await _locationManager.initialize(mapboxMap);
      await _styleManager!.initializeClusters();
      await _styleManager!.hidePoiLayers();

      if (!mounted) return;

      final countryCode = ref.read(authControllerProvider).user?.countryCode;
      
      // 1. Immediately set camera to fallback country (prevents map from starting at 0,0)
      await mapboxMap.setCamera(
        CameraOptions(
          center: _getCountryCenter(countryCode),
          zoom: 5, 
        ),
      );

      await _renderMarkers();
      
      // 2. Request user location. If found, it will pan to their exact house.
      // We don't await this so it doesn't block the rest of the map initialization
      // if the GPS sensor hangs.
      _locationManager.enableUserLocation(
        onFirstFix: (point) {
          if (mounted && mapboxMap != null) {
            mapboxMap.setCamera(CameraOptions(center: point, zoom: 14));
          }
        },
      );
    } on Exception catch (e) {
      debugPrint('Error initializing map: $e');
    }
  }

  Point _getCountryCenter(String? countryCode) {
    // Default to Philippines if no country code or unrecognized
    final fallback = Point(coordinates: Position(121.7740, 12.8797));
    if (countryCode == null) return fallback;

    switch (countryCode.toUpperCase()) {
      case 'PH':
        return Point(coordinates: Position(121.7740, 12.8797));
      case 'US':
        return Point(coordinates: Position(-95.7129, 37.0902));
      case 'ID':
        return Point(coordinates: Position(113.9213, -0.7893));
      case 'MY':
        return Point(coordinates: Position(101.9758, 4.2105));
      case 'SG':
        return Point(coordinates: Position(103.8198, 1.3521));
      default:
        return fallback;
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
      max: ScreenCoordinate(x: screenPoint.x + 20, y: screenPoint.y + 20),
    );

    final features = await mapboxMap!.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenBox(screenBox),
      RenderedQueryOptions(
        layerIds: ['clusters', 'unclustered-point', 'cluster-count'],
      ),
    );

    if (features.isNotEmpty) {
      final firstFeature = features.first;
      if (firstFeature == null) return;

      final geoJsonFeature = firstFeature.queriedFeature.feature;
      final properties = geoJsonFeature['properties'] as Map?;

      if (properties != null) {
        final isCluster = properties['cluster'] == true ||
            properties.containsKey('cluster_id') ||
            properties.containsKey('point_count');
        if (isCluster) {
          final currentCamera = await mapboxMap!.getCameraState();
          await mapboxMap!.setCamera(
            CameraOptions(
              center: point,
              zoom: currentCamera.zoom + 2,
            ),
          );
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
      unawaited(_styleManager?.updateSelectedStore(_selectedStoreId));
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
            unawaited(_styleManager?.updateSelectedStore(null));
          }
        }),
      );
    }
  }

  Future<void> _renderMarkers() async {
    if (_styleManager == null) return;

    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];
    await _styleManager!.updateGeoJsonSource(stores);
  }

  Future<void> _onCameraIdle() async {
    if (mapboxMap == null || !mounted) return;

    final cameraState = await mapboxMap!.getCameraState();
    final center = cameraState.center;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // Wait 750ms after the camera stops moving before fetching new stores.
    _debounceTimer = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      final lat = center.coordinates.lat.toDouble();
      final lng = center.coordinates.lng.toDouble();
      unawaited(
        ref.read(worldMapControllerProvider.notifier).fetchStoresAtLocation(
              north: lat + 0.05,
              south: lat - 0.05,
              east: lng + 0.05,
              west: lng - 0.05,
            ),
      );
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

    if (_currentRoute != null) {
      await polylineAnnotationManager!.delete(_currentRoute!);
      _currentRoute = null;
    }

    // Fetch real road-following route from Mapbox Directions API.
    // Falls back to a straight line if the API is unreachable.
    List<Position> routeCoords;
    try {
      routeCoords = await _directionsDatasource.getRoute(
        origin: userPoint.coordinates,
        destination: Position(store.lng, store.lat),
      );
    } on Exception catch (e) {
      debugPrint('Directions API failed, using straight line: $e');
      routeCoords = [
        userPoint.coordinates,
        Position(store.lng, store.lat),
      ];
    }

    if (routeCoords.isEmpty) {
      routeCoords = [
        userPoint.coordinates,
        Position(store.lng, store.lat),
      ];
    }

    _currentRoute = await polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: routeCoords),
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
          zoom: 16,
          pitch: 60,
          bearing: 0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _storesSubscription?.close();

    final cancelRoute = polylineAnnotationManager?.deleteAll();
    if (cancelRoute != null) unawaited(cancelRoute);

    unawaited(_locationManager.dispose());

    polylineAnnotationManager = null;
    mapboxMap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    unawaited(_onCameraIdle());
                  },
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
                    onStyleSelected: (style) async {
                      if (mapboxMap == null) return;
                      setState(() {
                        _mapStyle = style;
                      });

                      await mapboxMap!.loadStyleURI(style);

                      // After a style change, all custom layers and the
                      // GeoJSON source are wiped by Mapbox — re-add them.
                      await _styleManager!.initializeClusters();
                      await _styleManager!.hidePoiLayers();
                      await _renderMarkers();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showListView) StoreListView(onNavigate: _startNavigationTo),
        ],
      ),
    );
  }
}
