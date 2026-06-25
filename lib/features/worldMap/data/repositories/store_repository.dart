import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Repository contract (the abstraction the domain layer depends on).
// ignore: one_member_abstracts
abstract class StoreRepository {
  Future<Either<Failure, List<StoreEntity>>> getNearbyStores({
    required double lat,
    required double lng,
    double radius = 10,
  });
}

/// Fetches stores from the remote data source and maps the data layer's typed
/// exceptions into typed [Failure] values. Errors are returned, never thrown
/// or silently swallowed.
class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._remote);

  final StoreRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<StoreEntity>>> getNearbyStores({
    required double lat,
    required double lng,
    double radius = 10,
  }) async {
    try {
      final stores = await _remote.getNearbyStores(
        lat: lat,
        lng: lng,
        radius: radius,
      );
      return Right(stores);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
