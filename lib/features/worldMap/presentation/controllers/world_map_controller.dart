import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/data/repositories/store_repository.dart';
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

/// Bridges a domain [Failure] into the async error channel. [AsyncNotifier]
/// reports errors by throwing, and the linter requires thrown objects to be
/// [Exception]s — so we wrap the typed failure instead of throwing it directly.
class StoreLoadException implements Exception {
  StoreLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}

// --- Controller ---

/// Loads the stores shown on the world map. Surfaces loading, data, and error
/// as an [AsyncValue] so the UI can render each state explicitly. A [Failure]
/// from the use case is thrown into the error channel and read back in the UI.
class WorldMapController extends AsyncNotifier<List<StoreEntity>> {
  @override
  Future<List<StoreEntity>> build() => _fetchNearbyStores();

  Future<List<StoreEntity>> _fetchNearbyStores() async {
    // Try to get GPS to fetch nearby stores on first load.
    // If GPS is unavailable, return an empty list — the camera-idle
    // listener will kick off a proper fetch once the map is positioned.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final lat = position.latitude;
      final lng = position.longitude;

      final result = await ref.read(getNearbyStoresUseCaseProvider)(
        north: lat + 0.05,
        south: lat - 0.05,
        east: lng + 0.05,
        west: lng - 0.05,
        centerLat: lat,
        centerLng: lng,
      );
      return result.fold(
        (failure) => <StoreEntity>[],
        (stores) => stores,
      );
    } on Exception catch (_) {
      // GPS failed or timed out — map will still open, stores load on pan.
      return <StoreEntity>[];
    }
  }

  /// Manually update stores at a specific location without needing GPS.
  /// Does NOT set loading state — we silently fetch so existing pins don't
  /// disappear while the new request is in flight.
  Future<void> fetchStoresAtLocation({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
  }) async {
    final result = await ref.read(getNearbyStoresUseCaseProvider)(
      north: north,
      south: south,
      east: east,
      west: west,
      centerLat: centerLat,
      centerLng: centerLng,
    );

    state = result.fold(
      (failure) => AsyncValue.error(
        StoreLoadException(failure),
        StackTrace.current,
      ),
      (newStores) {
        // Always merge with existing stores (even if newStores is empty).
        // This replaces any error/loading state with a valid data state.
        final currentStores = state.valueOrNull ?? [];
        if (newStores.isEmpty) {
          return AsyncValue.data(currentStores);
        }

        final storeMap = <String, StoreEntity>{
          for (final s in currentStores) s.id: s,
        };
        for (final s in newStores) {
          storeMap[s.id] = s;
        }

        final mergedList = storeMap.values.toList();
        if (mergedList.length > 500) {
          return AsyncValue.data(
            mergedList.sublist(mergedList.length - 500),
          );
        }
        return AsyncValue.data(mergedList);
      },
    );
  }

  /// Re-fetches, showing a loading spinner while the request is in flight.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchNearbyStores);
  }
}

final worldMapControllerProvider =
    AsyncNotifierProvider<WorldMapController, List<StoreEntity>>(
      WorldMapController.new,
    );
