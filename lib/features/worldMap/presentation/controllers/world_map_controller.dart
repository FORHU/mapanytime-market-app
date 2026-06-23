import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // Jakarta — the demo query origin until real geolocation is wired in.
  static const double _originLat = -6.2088;
  static const double _originLng = 106.8456;

  @override
  Future<List<StoreEntity>> build() => _fetchNearbyStores();

  Future<List<StoreEntity>> _fetchNearbyStores() async {
    final result = await ref.read(getNearbyStoresUseCaseProvider)(
      lat: _originLat,
      lng: _originLng,
    );
    return result.fold(
      (failure) => throw StoreLoadException(failure),
      (stores) => stores,
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
