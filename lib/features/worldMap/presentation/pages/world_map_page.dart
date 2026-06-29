// The Mapbox plugin uses some deprecated interfaces.
// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final bool _showListView = false;

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
        // Only re-render when we have actual data to show.
        // Skip loading/error transitions to avoid clearing the map.
        if (next.hasValue) {
          unawaited(_renderMarkers());
        }
      },
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    _styleManager = MapboxStyleManager(mapboxMap, onStoreTap: _selectStore);

    try {
      if (!mounted) return;

      final countryCode = ref.read(authControllerProvider).user?.countryCode;
      
      // 1. Immediately set camera to fallback country (prevents map from
      // starting at 0,0)
      await mapboxMap.setCamera(
        CameraOptions(
          center: _getCountryCenter(countryCode),
          zoom: 5, 
        ),
      );

      // The rest of the initialization (layers, GPS annotations) will happen
      // in _onStyleLoaded
    } on Exception catch (e) {
      debugPrint('Error initializing map: $e');
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    if (mapboxMap == null || !mounted) return;

    try {
      // Recreate managers since styles wipe layers/annotations
      polylineAnnotationManager =
          await mapboxMap!.annotations.createPolylineAnnotationManager();
      
      await _locationManager.initialize(mapboxMap!);
      await _styleManager!.initializeStoreLayers();
      debugPrint('_onStyleLoaded: initializeStoreLayers done');
      await _styleManager!.hidePoiLayers();
      await _renderMarkers();
      debugPrint('_onStyleLoaded: renderMarkers done');

      // Trigger an initial store fetch for the current camera position.
      // This ensures stores appear without the user needing to pan.
      final cameraState = await mapboxMap!.getCameraState();
      final center = cameraState.center;
      final lat = center.coordinates.lat.toDouble();
      final lng = center.coordinates.lng.toDouble();
      final zoom = cameraState.zoom;
      final span = math.max(0.05, 360.0 / math.pow(2, zoom));
      unawaited(
        ref.read(worldMapControllerProvider.notifier).fetchStoresAtLocation(
          north: lat + span,
          south: lat - span,
          east: lng + span,
          west: lng - span,
          centerLat: lat,
          centerLng: lng,
        ),
      );

      // Start/Resume tracking user location
      unawaited(_locationManager.enableUserLocation(
        onFirstFix: (point) {
          if (mounted && mapboxMap != null) {
            unawaited(mapboxMap!.setCamera(
              CameraOptions(center: point, zoom: 14),
            ));
          }
        },
      ));
    } on Exception catch (e) {
      debugPrint('Error handling style loaded: $e\n$e');
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
      final zoom = cameraState.zoom;
      
      // Calculate dynamic bounds based on zoom level.
      // At zoom 5 (country level), this will fetch a very large area 
      // (e.g. the whole Philippines)
      // At zoom 14+ (street level), this will fetch a small radius 
      // (0.05 degrees ~ 5km).
      final span = math.max(0.05, 360.0 / math.pow(2, zoom));
      
      unawaited(
        ref.read(worldMapControllerProvider.notifier).fetchStoresAtLocation(
              north: lat + span,
              south: lat - span,
              east: lng + span,
              west: lng - span,
              centerLat: lat,
              centerLng: lng,
            ),
      );
    });
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
                  onStyleLoadedListener: _onStyleLoaded,
                  onCameraChangeListener: (_) {
                    unawaited(_onCameraIdle());
                  },
                ),

                // Fills the map so the overlay's internal Stack has bounded
                // constraints (centered spinner, bottom-anchored error card).
                const Positioned.fill(
                  child: WorldMapStatusOverlay(),
                ),

                // SEARCH BAR
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      // TODO(Phase2): Open full search screen
                      debugPrint('Search tapped');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54),
                          const SizedBox(width: 12),
                          Text(
                            'Search stores or products...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 16,
                  right: 16,
                  child: WorldMapFloatingControls(
                    onLocateMe: () {
                      final point = _locationManager.getUserLocation();
                      if (point != null && mapboxMap != null) {
                        unawaited(mapboxMap!.setCamera(CameraOptions(
                          center: point,
                          zoom: 15,
                        )));
                      }
                    },
                    onStyleSelected: (style) async {
                      if (mapboxMap == null) return;
                      setState(() {
                        _mapStyle = style;
                      });

                      await mapboxMap!.loadStyleURI(style);
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
