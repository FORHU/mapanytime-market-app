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
    var lat = 0.0;
    var lng = 0.0;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } on Exception catch (_) {
      throw Exception('GPS Location is required to find nearby stores.');
    }

    final result = await ref.read(getNearbyStoresUseCaseProvider)(
      north: lat + 0.05,
      south: lat - 0.05,
      east: lng + 0.05,
      west: lng - 0.05,
    );
    return result.fold(
      (failure) => throw StoreLoadException(failure),
      (stores) => stores,
    );
  }

  /// Manually update stores at a specific location without needing GPS
  Future<void> fetchStoresAtLocation({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref.read(getNearbyStoresUseCaseProvider)(
      north: north,
      south: south,
      east: east,
      west: west,
    );
    
    state = result.fold(
      (failure) => AsyncValue.error(
        StoreLoadException(failure),
        StackTrace.current,
      ),
      (newStores) {
        final currentStores = state.valueOrNull ?? [];
        // Use a map to deduplicate stores by ID
        final Map<String, StoreEntity> storeMap = {
          for (final s in currentStores) s.id: s,
        };
        for (final s in newStores) {
          storeMap[s.id] = s;
        }
        
        final mergedList = storeMap.values.toList();
        // Keep a maximum of 500 stores in memory to prevent performance degradation
        // We drop from the beginning of the list (older camera centers)
        if (mergedList.length > 500) {
          return AsyncValue.data(mergedList.sublist(mergedList.length - 500));
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
