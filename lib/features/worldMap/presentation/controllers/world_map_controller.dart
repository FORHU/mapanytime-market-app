import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/worldMap/data/datasources/category_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/store_socket_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/data/repositories/store_repository.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_category.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/usecases/get_nearby_stores_usecase.dart';

// --- Dependency wiring (Riverpod providers) ---

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final remote = StoreRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return StoreRepositoryImpl(remote);
});

final getNearbyStoresUseCaseProvider = Provider<GetNearbyStoresUseCase>(
  (ref) => GetNearbyStoresUseCase(ref.watch(storeRepositoryProvider)),
);

/// Realtime store-updates socket (region-scoped). Disposed with the provider.
final storeSocketProvider = Provider<StoreSocketDataSource>((ref) {
  final socket = StoreSocketDataSource(AppConfig.instance.socketUrl);
  ref.onDispose(socket.dispose);
  return socket;
});

/// Parent categories for the map filter chips, fetched from the API so they
/// always match the backend's seeded categories.
final mapCategoriesProvider = FutureProvider<List<StoreCategory>>((ref) {
  final ds = CategoryRemoteDataSource(ref.watch(apiServiceProvider));
  return ds.getParentCategories();
});

/// Bridges a domain [Failure] into the async error channel. [AsyncNotifier]
/// reports errors by throwing, and the linter requires thrown objects to be
/// [Exception]s — so we wrap the typed failure instead of throwing it directly.
class StoreLoadException implements Exception {
  StoreLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}

/// The map's store state: the (merged) markers plus pagination info for the
/// current viewport so the UI can offer "load more" / "showing X of Y".
class WorldMapData extends Equatable {
  const WorldMapData({
    this.stores = const [],
    this.total = 0,
    this.hasMore = false,
  });

  final List<StoreEntity> stores;

  /// Total stores in the current viewport (across all pages).
  final int total;

  /// Whether more pages exist for the current viewport.
  final bool hasMore;

  @override
  List<Object?> get props => [stores, total, hasMore];
}

/// The bounding box + center the current pages were fetched for. Retained so
/// [WorldMapController.loadMore] can request the next page of the same box.
class _Viewport {
  const _Viewport({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    this.centerLat,
    this.centerLng,
  });

  final double north;
  final double south;
  final double east;
  final double west;
  final double? centerLat;
  final double? centerLng;
}

// --- Controller ---

/// Loads the stores shown on the world map. Surfaces loading, data, and error
/// as an [AsyncValue] so the UI can render each state explicitly. A [Failure]
/// from the use case is thrown into the error channel and read back in the UI.
class WorldMapController extends AsyncNotifier<WorldMapData> {
  /// Hard cap on merged markers kept in memory (protects the map/GeoJSON
  /// source from an unbounded set as the user pans across many viewports).
  static const _maxStores = 500;

  _Viewport? _viewport;

  // Server offset already consumed for the current viewport.
  int _loadedOffset = 0;
  bool _loadingMore = false;

  StoreSocketDataSource? _socket;

  @override
  Future<WorldMapData> build() {
    _setupSocket();
    return _fetchInitial();
  }

  /// Connects the realtime socket and merges its events into the map state.
  /// Subscriptions are torn down when this notifier is disposed.
  void _setupSocket() {
    final socket = ref.read(storeSocketProvider)..connect();
    _socket = socket;

    final upSub = socket.onUpserted.listen(_onStoreUpserted);
    final rmSub = socket.onRemoved.listen(_onStoreRemoved);
    ref.onDispose(() {
      unawaited(upSub.cancel());
      unawaited(rmSub.cancel());
    });
  }

  /// Tells the socket to stream updates for the current viewport.
  void _subscribeSocket(_Viewport vp) {
    _socket?.subscribe(
      north: vp.north,
      south: vp.south,
      east: vp.east,
      west: vp.west,
    );
  }

  /// A store appeared/changed within the subscribed region — upsert its marker.
  void _onStoreUpserted(StoreEntity store) {
    final data = state.value;
    if (data == null) return;
    state = AsyncValue.data(
      WorldMapData(
        stores: _merge(data.stores, [store]),
        total: data.total,
        hasMore: data.hasMore,
      ),
    );
  }

  /// A store was removed/deactivated — drop its marker if present.
  void _onStoreRemoved(String id) {
    final data = state.value;
    if (data == null || !data.stores.any((s) => s.id == id)) return;
    state = AsyncValue.data(
      WorldMapData(
        stores: data.stores.where((s) => s.id != id).toList(),
        total: data.total,
        hasMore: data.hasMore,
      ),
    );
  }

  Future<WorldMapData> _fetchInitial() async {
    // Try to get GPS to fetch nearby stores on first load. If GPS is
    // unavailable, return empty — the camera-idle listener fetches once the
    // map is positioned.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final lat = position.latitude;
      final lng = position.longitude;

      final viewport = _Viewport(
        north: lat + 0.05,
        south: lat - 0.05,
        east: lng + 0.05,
        west: lng - 0.05,
        centerLat: lat,
        centerLng: lng,
      );
      _viewport = viewport;
      _loadedOffset = 0;
      _subscribeSocket(viewport);

      final result = await ref.read(getNearbyStoresUseCaseProvider)(
        north: viewport.north,
        south: viewport.south,
        east: viewport.east,
        west: viewport.west,
        centerLat: lat,
        centerLng: lng,
      );

      return await result.fold(
        (failure) async => const WorldMapData(),
        (page) async {
          _loadedOffset = page.stores.length;
          // If there are more pages, start a background auto-pager to
          // progressively fetch remaining pages (throttled) so the map
          // eventually contains all stores for the viewport without
          // requiring user interaction.
          if (page.hasMore) unawaited(_autoLoadRemaining());
          return WorldMapData(
            stores: page.stores,
            total: page.total,
            hasMore: page.hasMore,
          );
        },
      );
    } on Exception catch (_) {
      // GPS failed or timed out — map will still open, stores load on pan.
      return const WorldMapData();
    }
  }

  /// Background auto-pager: repeatedly calls [loadMore] with a small delay
  /// until the viewport has been fully loaded (or limits reached).
  Future<void> _autoLoadRemaining() async {
    var safety = 0;
    while (true) {
      final data = state.value;
      final viewport = _viewport;
      if (data == null || viewport == null) return;
      if (!data.hasMore) return;
      if (data.stores.length >= _maxStores) return;

      // If a manual/other load is already in flight, wait a bit.
      if (_loadingMore) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }

      await loadMore();

      // Throttle subsequent page requests so pagination feels gradual.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      safety += 1;
      if (safety > 200) return;
    }
  }

  /// Fetch the first page for a new viewport (e.g. after a camera pan). Merges
  /// the results into the existing markers so pins don't flicker, and resets
  /// pagination to this viewport. Does NOT set a loading state.
  String? _selectedCategoryId;

  Future<void> fetchStoresAtLocation({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
    String? categoryId,
  }) async {
    // A changed category means a different result set — replace the markers
    // rather than merging, so the previous category's pins don't linger.
    final categoryChanged = categoryId != _selectedCategoryId;

    final viewport = _Viewport(
      north: north,
      south: south,
      east: east,
      west: west,
      centerLat: centerLat,
      centerLng: centerLng,
    );
    _viewport = viewport;
    _loadedOffset = 0;
    _selectedCategoryId = categoryId;
    _subscribeSocket(viewport);

    final result = await ref.read(getNearbyStoresUseCaseProvider)(
      north: north,
      south: south,
      east: east,
      west: west,
      centerLat: centerLat,
      centerLng: centerLng,
      categoryId: categoryId,
    );

    state = result.fold(
      (failure) => AsyncValue.error(
        StoreLoadException(failure),
        StackTrace.current,
      ),
      (page) {
        _loadedOffset = page.stores.length;
        final merged = categoryChanged
            ? page.stores
            : _merge(state.value?.stores ?? const [], page.stores);
        if (page.hasMore) unawaited(_autoLoadRemaining());
        return AsyncValue.data(
          WorldMapData(
            stores: merged,
            total: page.total,
            hasMore: page.hasMore,
          ),
        );
      },
    );
  }

  /// Loads the next page for the current viewport and merges it in. No-op if
  /// there's nothing more, no viewport yet, or a load is already in flight.
  Future<void> loadMore() async {
    final data = state.value;
    final viewport = _viewport;
    if (_loadingMore || data == null || !data.hasMore || viewport == null) {
      return;
    }

    _loadingMore = true;
    try {
      final result = await ref.read(getNearbyStoresUseCaseProvider)(
        north: viewport.north,
        south: viewport.south,
        east: viewport.east,
        west: viewport.west,
        centerLat: viewport.centerLat,
        centerLng: viewport.centerLng,
        categoryId: _selectedCategoryId,
        offset: _loadedOffset,
      );

      result.fold(
        // Keep the current data on failure — loadMore is best-effort.
        (failure) {},
        (page) {
          _loadedOffset += page.stores.length;
          final merged = _merge(data.stores, page.stores);
          state = AsyncValue.data(
            WorldMapData(
              stores: merged,
              total: page.total,
              hasMore: page.hasMore,
            ),
          );
        },
      );
    } finally {
      _loadingMore = false;
    }
  }

  /// Dedup-merge incoming stores into the current set (by id), capped to
  /// [_maxStores] (newest kept).
  List<StoreEntity> _merge(
    List<StoreEntity> current,
    List<StoreEntity> incoming,
  ) {
    if (incoming.isEmpty) return current;

    final storeMap = <String, StoreEntity>{
      for (final s in current) s.id: s,
    };
    for (final s in incoming) {
      storeMap[s.id] = s;
    }

    final merged = storeMap.values.toList();
    if (merged.length > _maxStores) {
      return merged.sublist(merged.length - _maxStores);
    }
    return merged;
  }

  /// Re-fetches, showing a loading spinner while the request is in flight.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchInitial);
  }
}

final worldMapControllerProvider =
    AsyncNotifierProvider<WorldMapController, WorldMapData>(
      WorldMapController.new,
    );
