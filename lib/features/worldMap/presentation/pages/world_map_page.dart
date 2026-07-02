import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/core/utils/platform_support.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/directions_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_category.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/mapbox_style_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/user_location_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_list_view.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_floating_controls.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_status_overlay.dart';
import 'package:mapanytime_market_app/shared/widgets/app_state_view.dart';
import 'package:mapanytime_market_app/shared/widgets/category_chip.dart';
import 'package:mapanytime_market_app/shared/widgets/floating_search_bar.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Maps a (backend-driven) category name to a chip icon. Falls back to a
/// generic storefront icon for names we don't have a specific glyph for.
IconData _iconForCategory(String name) {
  switch (name) {
    case 'Food & Beverage':
      return Icons.restaurant_rounded;
    case 'Shopping & Retail':
      return Icons.checkroom_rounded;
    case 'Electronics':
      return Icons.devices_rounded;
    case 'Home & Living':
      return Icons.chair_rounded;
    case 'Health & Wellness':
      return Icons.spa_rounded;
    case 'Automotive':
      return Icons.directions_car_rounded;
    case 'Pets':
      return Icons.pets_rounded;
    case 'Sports & Outdoors':
      return Icons.sports_basketball_rounded;
    case 'Entertainment':
      return Icons.movie_rounded;
    case 'Baby & Kids':
      return Icons.child_care_rounded;
    case 'Services':
      return Icons.handyman_rounded;
    case 'Agriculture':
      return Icons.agriculture_rounded;
    case 'Industrial & Business':
      return Icons.factory_rounded;
    default:
      return Icons.storefront_rounded;
  }
}

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
  int _selectedCategory = 0;

  // Route State
  PolylineAnnotationManager? polylineAnnotationManager;
  PolylineAnnotation? _currentRoute;
  final _directionsDatasource = DirectionsDatasource();

  Timer? _debounceTimer;
  String _mapStyle = 'mapbox://styles/mapbox/streets-v12';

  // Full-screen loader shown only on the very first render, until the map has
  // centered on the user's location (or a fallback timeout elapses). Never
  // shown again for later camera moves / store fetches.
  bool _initializing = true;
  Timer? _initTimer;

  // Riverpod listener — registered once in initState, cancelled in dispose
  ProviderSubscription<AsyncValue<WorldMapData>>? _storesSubscription;

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
      polylineAnnotationManager = await mapboxMap!.annotations
          .createPolylineAnnotationManager();

      await _locationManager.initialize(mapboxMap!);
      await _styleManager!.initializeStoreLayers();
      await _styleManager!.hidePoiLayers();
      await _renderMarkers();

      // Trigger an initial store fetch for the current camera position.
      // This ensures stores appear without the user needing to pan.
      final cameraState = await mapboxMap!.getCameraState();
      final center = cameraState.center;
      final lat = center.coordinates.lat.toDouble();
      final lng = center.coordinates.lng.toDouble();
      final zoom = cameraState.zoom;
      final span = math.max(0.05, 360.0 / math.pow(2, zoom));
      unawaited(
        ref
            .read(worldMapControllerProvider.notifier)
            .fetchStoresAtLocation(
              north: lat + span,
              south: lat - span,
              east: lng + span,
              west: lng - span,
              centerLat: lat,
              centerLng: lng,
              categoryId: _categoryIdForIndex(_selectedCategory),
            ),
      );

      // Start/Resume tracking user location
      unawaited(
        _locationManager.enableUserLocation(
          onFirstFix: (point) {
            if (mounted && mapboxMap != null) {
              unawaited(
                mapboxMap!.setCamera(
                  CameraOptions(center: point, zoom: 14),
                ),
              );
            }
            // We've centered on the user — dismiss the initial loader.
            _finishInitializing();
          },
        ),
      );

      // Fallback: if GPS is slow, denied, or unavailable, don't let the
      // initial loader hang — reveal the map (at the fallback country view)
      // after a few seconds.
      _initTimer = Timer(const Duration(seconds: 8), _finishInitializing);
    } on Exception catch (e) {
      debugPrint('Error handling style loaded: $e');
      _finishInitializing();
    }
  }

  /// Hides the one-time initial loader. Idempotent — safe to call from the
  /// first GPS fix, the fallback timer, or an init error.
  void _finishInitializing() {
    _initTimer?.cancel();
    if (mounted && _initializing) {
      setState(() => _initializing = false);
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

    final stores = ref.read(worldMapControllerProvider).value?.stores ?? [];
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

    final stores = ref.read(worldMapControllerProvider).value?.stores ?? [];
    await _styleManager!.updateGeoJsonSource(stores);
  }

  /// Resolves the selected chip index to a category id. Index 0 is "All"
  /// (no filter); the rest map into the fetched parent categories.
  String? _categoryIdForIndex(int index) {
    if (index <= 0) return null;
    final cats =
        ref.read(mapCategoriesProvider).value ?? const <StoreCategory>[];
    final i = index - 1;
    return (i >= 0 && i < cats.length) ? cats[i].id : null;
  }

  Future<void> _applyCategoryFilter(int index) async {
    if (mapboxMap == null || !mounted) return;
    final cameraState = await mapboxMap!.getCameraState();
    final center = cameraState.center;
    final lat = center.coordinates.lat.toDouble();
    final lng = center.coordinates.lng.toDouble();
    final zoom = cameraState.zoom;
    final span = math.max(0.05, 360.0 / math.pow(2, zoom));

    unawaited(
      ref
          .read(worldMapControllerProvider.notifier)
          .fetchStoresAtLocation(
            north: lat + span,
            south: lat - span,
            east: lng + span,
            west: lng - span,
            centerLat: lat,
            centerLng: lng,
            categoryId: _categoryIdForIndex(index),
          ),
    );
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
        ref
            .read(worldMapControllerProvider.notifier)
            .fetchStoresAtLocation(
              north: lat + span,
              south: lat - span,
              east: lng + span,
              west: lng - span,
              centerLat: lat,
              centerLng: lng,
              categoryId: _categoryIdForIndex(_selectedCategory),
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
        lineColor: AppColors.brand.primary.toARGB32(),
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
    _initTimer?.cancel();
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
    // mapbox_maps_flutter only supports Android/iOS; rendering MapWidget or any
    // map overlay elsewhere (web, Windows, desktop) throws. Short-circuit to a
    // standalone message so the rest of the app stays testable there.
    if (!isMapboxSupported) {
      return const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.surfaceGradient),
          child: SizedBox.expand(
            child: AppStateView(
              icon: Icons.map_outlined,
              title: 'Map unavailable',
              message:
                  'The interactive map runs on Android and iOS only.\n'
                  'Open the app on a mobile device or emulator to view it.',
            ),
          ),
        ),
      );
    }

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

                // SEARCH BAR + CATEGORY FILTERS (glass overlay)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingSearchBar(
                        onTap: () {
                          // TODO(Phase2): Open full search screen
                        },
                        onFilterTap: () {
                          // TODO(Phase2): Open filter sheet
                        },
                      ),
                      const Gap(AppSpacing.sm),
                      SizedBox(
                        height: 40,
                        child: Consumer(
                          builder: (context, ref, _) {
                            // Chips: "All" + parent categories from the API.
                            final cats =
                                ref.watch(mapCategoriesProvider).value ??
                                const <StoreCategory>[];
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: cats.length + 1,
                              separatorBuilder: (_, _) =>
                                  const Gap(AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final isAll = i == 0;
                                final label = isAll ? 'All' : cats[i - 1].name;
                                final icon = isAll
                                    ? Icons.grid_view_rounded
                                    : _iconForCategory(cats[i - 1].name);
                                return CategoryChip(
                                  label: label,
                                  icon: icon,
                                  selected: _selectedCategory == i,
                                  onTap: () {
                                    setState(() => _selectedCategory = i);
                                    if (mapboxMap == null) return;
                                    unawaited(_applyCategoryFilter(i));
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Manual "Load more" removed — controller auto-loads remaining
                // pages in background so the map is progressively populated
                // without user interaction.
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: WorldMapFloatingControls(
                    onLocateMe: () {
                      final point = _locationManager.getUserLocation();
                      if (point != null && mapboxMap != null) {
                        unawaited(
                          mapboxMap!.setCamera(
                            CameraOptions(
                              center: point,
                              zoom: 15,
                            ),
                          ),
                        );
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

          // One-time initial loader while we locate the user and center the
          // map. Sits above everything; dismissed on first GPS fix / timeout.
          if (_initializing) const Positioned.fill(child: _InitialMapLoader()),
        ],
      ),
    );
  }
}

/// Full-screen branded loader shown only on the map's first render.
class _InitialMapLoader extends StatelessWidget {
  const _InitialMapLoader();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.surfaceGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            Gap(AppSpacing.lg),
            Text(
              'Finding your location…',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Gap(AppSpacing.xs),
            Text(
              'Loading nearby stores',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
