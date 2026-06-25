import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/repositories/store_repository.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// A single business action. Callable like a function:
/// `getNearbyStoresUseCase(lat: ..., lng: ...)`.
class GetNearbyStoresUseCase {
  GetNearbyStoresUseCase(this.repository);
  final StoreRepository repository;

  Future<Either<Failure, List<StoreEntity>>> call({
    required double north,
    required double south,
    required double east,
    required double west,
  }) {
    return repository.getNearbyStores(
      north: north,
      south: south,
      east: east,
      west: west,
    );
  }
}
