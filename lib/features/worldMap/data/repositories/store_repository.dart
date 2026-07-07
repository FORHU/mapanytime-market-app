import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_page.dart';

/// Repository contract (the abstraction the domain layer depends on).
// ignore: one_member_abstracts
abstract class StoreRepository {
  Future<Either<Failure, StorePage>> getNearbyStores({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
    String? categoryId,
    String? search,
    int limit,
    int offset,
  });
}

/// Fetches stores from the remote data source and maps the data layer's typed
/// exceptions into typed [Failure] values. Errors are returned, never thrown
/// or silently swallowed.
class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._remote);

  final StoreRemoteDataSource _remote;

  @override
  Future<Either<Failure, StorePage>> getNearbyStores({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
    String? categoryId,
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final page = await _remote.getNearbyStores(
        north: north,
        south: south,
        east: east,
        west: west,
        centerLat: centerLat,
        centerLng: centerLng,
        categoryId: categoryId,
        search: search,
        limit: limit,
        offset: offset,
      );
      return Right(page);
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
