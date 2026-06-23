import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/repositories/store_repository.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// A single business action. Callable like a function:
/// `getNearbyStoresUseCase(lat: ..., lng: ...)`.
class GetNearbyStoresUseCase {
  GetNearbyStoresUseCase(this._repository);

  final StoreRepository _repository;

  Future<Either<Failure, List<StoreEntity>>> call({
    required double lat,
    required double lng,
  }) => _repository.getNearbyStores(lat: lat, lng: lng);
}
