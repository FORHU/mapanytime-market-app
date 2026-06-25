import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Repository contract (the abstraction the domain layer depends on).
// ignore: one_member_abstracts
abstract class StoreRepository {
  Future<Either<Failure, List<StoreEntity>>> getNearbyStores({
    required double north,
    required double south,
    required double east,
    required double west,
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
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    try {
      final stores = await _remote.getNearbyStores(
        north: north,
        south: south,
        east: east,
        west: west,
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
