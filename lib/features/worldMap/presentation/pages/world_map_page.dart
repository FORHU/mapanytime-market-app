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
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/store_clusterer.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/user_location_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/cluster_stores_sheet.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/navigation_mode_pill.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_floating_card.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_list_view.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_floating_controls.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/world_map_status_overlay.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
import 'package:mapanytime_market_app/shared/widgets/app_state_view.dart';
import 'package:mapanytime_market_app/shared/widgets/category_chip.dart';
import 'package:mapanytime_market_app/shared/widgets/floating_search_bar.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
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
  int _selectedCategory = 0;

  // Route State
  PolylineAnnotationManager? polylineAnnotationManager;
  PolylineAnnotation? _currentRoute;
  final _directionsDatasource = DirectionsDatasource();

  // Navigation state — non-null while a route is drawn on the map.
  StoreEntity? _navigatingTo;
  TravelMode _activeMode = TravelMode.driving;

  Timer? _debounceTimer;
  String _mapStyle = 'mapbox://styles/mapbox/streets-v12';

  // Clustering. Zoom is tracked separately from the store-refetch debounce
  // above: re-clustering is a local recompute over already-loaded stores,
  // not a network request, so it runs on its own much shorter debounce
  // rather than waiting the full 750ms meant for the fetch.
  double _currentZoom = 12;
  Timer? _reclusterDebounceTimer;

  // A non-building cluster is flown to a higher zoom on tap rather than
  // shown as a sheet. Capped here rather than at the map's own max zoom:
  // by this zoom, StoreClusterer's grid cell (~18m at 19) already
  // approaches the building-group threshold (20m), so anything that hasn't
  // split into singles or a building group by then genuinely won't from
  // further zooming — that's the fallback-to-sheet case.
  static const double _clusterZoomCeiling = 19;

  // Store search: text field + its own debounce (independent of the
  // camera-idle debounce above).
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

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
    _storesSubscription ??= ref.listenManual(worldMapControllerProvider, (
      previous,
      next,
    ) {
      // Only re-render when we have actual data to show.
      // Skip loading/error transitions to avoid clearing the map.
      if (next.hasValue) {
        unawaited(_renderMarkers());
      }
    });
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    _styleManager = MapboxStyleManager(
      mapboxMap,
      screenWidth: MediaQuery.sizeOf(context).width,
      onStoreTap: _selectStore,
      onClusterTap: _handleClusterTap,
    );

    unawaited(
      mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
    );

    try {
      if (!mounted) return;

      final countryCode = ref.read(authControllerProvider).user?.countryCode;

      // 1. Immediately set camera to fallback country (prevents map from
      // starting at 0,0)
      await mapboxMap.setCamera(
        CameraOptions(center: _getCountryCenter(countryCode), zoom: 5),
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
                mapboxMap!.setCamera(CameraOptions(center: point, zoom: 14)),
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
    }
    _styleManager?.setSelectedStore(storeId);

    final stores = ref.read(worldMapControllerProvider).value?.stores ?? [];
    final store = stores.where((s) => s.id == storeId).firstOrNull;
    if (store != null) {
      // Marker scale now tracks the live camera zoom on every frame via a
      // cheap native call (no bitmap swap), so it eases in smoothly as this
      // flyTo animates in rather than needing a pre-emptive jump here.
      unawaited(
        mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(store.lng, store.lat)),
            zoom: 17,
          ),
          MapAnimationOptions(duration: 900),
        ),
      );
    }
  }

  void _deselectStore() {
    _styleManager?.setSelectedStore(null);
    if (!mounted) return;
    setState(() => _selectedStoreId = null);
  }

  /// A building group always opens the sheet — it's already the terminal,
  /// unsplittable state (see `StoreClusterer.buildingGroupThresholdMeters`).
  /// A plain count cluster zooms to frame its members instead, *unless* we're
  /// already at `_clusterZoomCeiling`, where zooming further would not
  /// usefully separate them — the fallback that keeps a dense cluster tap
  /// from ever being a dead tap.
  ///
  /// Returns void rather than a Future so it still satisfies
  /// `MapboxStyleManager.onClusterTap`'s `void Function(StoreCluster)`.
  void _handleClusterTap(StoreCluster cluster) {
    if (cluster.isBuildingGroup || _currentZoom >= _clusterZoomCeiling) {
      _showClusterSheet(cluster);
      return;
    }
    unawaited(_zoomToCluster(cluster));
  }

  void _showClusterSheet(StoreCluster cluster) {
    unawaited(
      ClusterStoresSheet.show(
        context,
        cluster: cluster,
        onNavigate: (store) => unawaited(_startNavigationTo(store)),
      ),
    );
  }

  /// Frames every member of [cluster] on screen.
  ///
  /// The camera is computed by Mapbox from the members' own coordinates
  /// rather than guessed from a zoom increment: a fixed increment ignores how
  /// large the cluster actually is, and centering on the centroid pushes
  /// outliers off screen whenever the members aren't evenly spread.
  Future<void> _zoomToCluster(StoreCluster cluster) async {
    final map = mapboxMap;
    if (map == null) return;

    final points = cluster.stores
        .map((s) => Point(coordinates: Position(s.lng, s.lat)))
        .toList();

    final CameraOptions camera;
    try {
      camera = await map.cameraForCoordinatesPadding(
        points,
        // Flat and north-up: a fitted camera that inherited a navigation
        // pitch would frame the members against a tilted horizon.
        CameraOptions(bearing: 0, pitch: 0),
        _clusterFitPadding(),
        _clusterZoomCeiling,
        null,
      );
    } on Exception catch (e) {
      debugPrint('Could not compute a camera for cluster ${cluster.id}: $e');
      return;
    }

    if (!mounted) return;

    // Capped means the members are tighter than the grid can separate, so
    // moving there would land on this same cluster. Show the list instead of
    // a camera move that visibly changes nothing.
    final targetZoom = camera.zoom ?? _currentZoom;
    if (targetZoom >= _clusterZoomCeiling) {
      _showClusterSheet(cluster);
      return;
    }

    // easeTo, not flyTo: the cluster is already on screen, and flyTo's
    // deliberate zoom-out-then-in arc reads as a swoop over a short hop.
    // Duration tracks the actual distance travelled so a small step isn't
    // sluggish and a large one isn't abrupt.
    final delta = (targetZoom - _currentZoom).abs();
    final durationMs = (300 + delta * 130).clamp(300.0, 800.0).round();
    unawaited(map.easeTo(camera, MapAnimationOptions(duration: durationMs)));

    // Re-cluster for the destination zoom now, without waiting for the camera
    // to arrive — and note there is no way to wait for it even if we wanted
    // to: the platform interface for easeTo carries no completion callback,
    // so its Future resolves once the animation is *scheduled*.
    //
    // Doing it here is what actually fixes the lag. The camera debounce would
    // otherwise recluster 120ms after landing, and only then start fetching
    // and rasterizing each store's bitmap — leaving the cluster bubble parked
    // at the destination before it split. Reclustering up front means the
    // stores are resolving while the camera eases in, so they're there as it
    // arrives rather than popping in afterwards.
    _reclusterDebounceTimer?.cancel();
    _currentZoom = targetZoom;
    await _renderMarkers();
  }

  /// Insets the fitted camera must keep clear, so members don't land beneath
  /// the chrome floating over the map.
  ///
  /// Marker bitmaps are center-anchored and up to ~68dp tall plus shadow, so
  /// half a marker is reserved on every side — without it a correctly fitted
  /// edge marker still renders half-clipped.
  MbxEdgeInsets _clusterFitPadding() {
    const markerHalf = 40.0;
    // 16 offset + 54 search bar + 8 gap + 40 category chip row.
    const topChrome = 118.0;
    // Clears the bottom nav area. The floating controls stack is 104 tall but
    // only 48 wide at the right edge, so reserving all of it would cost every
    // fit a strip of vertical space for one corner.
    const bottomChrome = 56.0;

    final media = MediaQuery.of(context);
    var top = media.padding.top + topChrome + markerHalf;
    var bottom =
        media.padding.bottom + AppSpacing.sm + bottomChrome + markerHalf;

    // On a short screen the chrome can claim most of the viewport, and
    // padding that leaves no room produces a degenerate camera.
    final maxVertical = media.size.height * 0.6;
    if (top + bottom > maxVertical) {
      final scale = maxVertical / (top + bottom);
      top *= scale;
      bottom *= scale;
    }

    return MbxEdgeInsets(
      top: top,
      left: AppSpacing.md + markerHalf,
      bottom: bottom,
      right: AppSpacing.md + markerHalf,
    );
  }

  Future<void> _renderMarkers() async {
    if (_styleManager == null) return;

    final state = ref.read(worldMapControllerProvider).value;
    final stores = state?.stores ?? [];
    _styleManager!.isStoreListTruncated = state?.hasMore ?? false;
    final markers = StoreClusterer.cluster(stores, zoom: _currentZoom);
    await _styleManager!.updateGeoJsonSource(markers);
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

  /// Current search term, or null when the box is empty.
  String? get _searchOrNull {
    final term = _searchController.text.trim();
    return term.isEmpty ? null : term;
  }

  /// Refetches stores for the current camera viewport, always applying both the
  /// active category chip and the search term so the two filters travel
  /// together. Shared by the chip row, the search box, and camera-idle.
  Future<void> _refetchForCurrentCamera() async {
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
            categoryId: _categoryIdForIndex(_selectedCategory),
            search: _searchOrNull,
          ),
    );
  }

  /// Debounced store search: re-queries the current viewport for the term.
  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_refetchForCurrentCamera());
    });
  }

  Future<void> _onCameraIdle() async {
    if (mapboxMap == null || !mounted) return;

    final cameraState = await mapboxMap!.getCameraState();
    final center = cameraState.center;
    _currentZoom = cameraState.zoom;

    // Re-cluster on a much shorter debounce than the store refetch below:
    // this only recomputes over stores already loaded, so there's no
    // reason to wait a full 750ms just to reflect the new zoom on screen.
    _reclusterDebounceTimer?.cancel();
    _reclusterDebounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) unawaited(_renderMarkers());
    });

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
              search: _searchOrNull,
            ),
      );
    });
  }

  Future<void> _startNavigationTo(
    StoreEntity store, [
    TravelMode mode = TravelMode.driving,
  ]) async {
    final userPoint = _locationManager.getUserLocation();
    if (userPoint == null || polylineAnnotationManager == null) return;

    // Update navigation state.
    setState(() {
      _navigatingTo = store;
      _activeMode = mode;
    });

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
        mode: mode,
      );
    } on Exception catch (e) {
      debugPrint('Directions API failed, using straight line: $e');
      routeCoords = [userPoint.coordinates, Position(store.lng, store.lat)];
    }

    if (routeCoords.isEmpty) {
      routeCoords = [userPoint.coordinates, Position(store.lng, store.lat)];
    }

    _currentRoute = await polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: routeCoords),
        lineColor: AppColors.ink.toARGB32(),
        lineWidth: 5,
      ),
    );

    // Camera pitch varies by mode: driving = 3D (60°), others = overhead (45°).
    final pitch = mode == TravelMode.driving ? 60.0 : 45.0;
    unawaited(
      mapboxMap?.setCamera(
        CameraOptions(center: userPoint, zoom: 16, pitch: pitch, bearing: 0),
      ),
    );
  }

  void _cancelNavigation() {
    unawaited(polylineAnnotationManager?.deleteAll());
    _currentRoute = null;
    setState(() {
      _navigatingTo = null;
      _activeMode = TravelMode.driving;
    });
    // Reset camera pitch back to flat.
    unawaited(mapboxMap?.setCamera(CameraOptions(pitch: 0)));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _reclusterDebounceTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
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
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.ui.background),
          child: const SizedBox.expand(
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

    // Scaffold's extendBody:true already reports the floating bottom nav
    // pill's rendered height as this body's MediaQuery.padding.bottom —
    // that's the mechanism extendBody exists for. Add just a small gap on
    // top so overlays sit right above the pill instead of behind it.
    final navClearance = MediaQuery.of(context).padding.bottom + AppSpacing.sm;

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
                const Positioned.fill(child: WorldMapStatusOverlay()),

                // SEARCH BAR + CATEGORY FILTERS (glass overlay)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingSearchBar(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
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
                                    : iconForCategory(cats[i - 1].name);
                                return CategoryChip(
                                  label: label,
                                  icon: icon,
                                  selected: _selectedCategory == i,
                                  onTap: () {
                                    setState(() => _selectedCategory = i);
                                    if (mapboxMap == null) return;
                                    unawaited(_refetchForCurrentCamera());
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
                // Navigation mode pill — shown while a route is active.
                if (_navigatingTo != null)
                  Positioned(
                    bottom: navClearance,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: NavigationModePill(
                        selectedMode: _activeMode,
                        storeName: _navigatingTo!.name,
                        onModeChanged: (mode) =>
                            unawaited(_startNavigationTo(_navigatingTo!, mode)),
                        onCancel: _cancelNavigation,
                      ),
                    ),
                  ),

                if (_selectedStoreId != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: navClearance,
                    child: Builder(
                      builder: (context) {
                        final stores =
                            ref
                                .watch(worldMapControllerProvider)
                                .value
                                ?.stores ??
                            [];
                        final store = stores
                            .where((s) => s.id == _selectedStoreId)
                            .firstOrNull;
                        if (store == null) return const SizedBox.shrink();
                        return StoreFloatingCard(
                          key: ValueKey(store.id),
                          store: store,
                          onClose: _deselectStore,
                          onNavigate: () => _startNavigationTo(store),
                        );
                      },
                    ),
                  ),

                Positioned(
                  bottom: navClearance,
                  right: 16,
                  child: WorldMapFloatingControls(
                    onLocateMe: () {
                      final point = _locationManager.getUserLocation();
                      if (point != null && mapboxMap != null) {
                        unawaited(
                          mapboxMap!.setCamera(
                            CameraOptions(center: point, zoom: 15),
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
          if (_showListView)
            StoreListView(
              onNavigate: (store) => unawaited(_startNavigationTo(store)),
            ),

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
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.ui.background),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const Gap(AppSpacing.lg),
            const Text(
              'Finding your location…',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Gap(AppSpacing.xs),
            Text(
              'Loading nearby stores',
              style: TextStyle(fontSize: 13, color: AppColors.text.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
