import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/home/data/datasources/product_remote_datasource.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/product_page.dart';

/// Repository contract (the abstraction the domain layer depends on).
// ignore: one_member_abstracts
abstract class ProductRepository {
  Future<Either<Failure, ProductPage>> getAllProducts({
    String? categoryId,
    String? search,
    int page,
    int limit,
  });
}

/// Fetches products from the remote data source and maps the data layer's
/// typed exceptions into typed [Failure] values.
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProductPage>> getAllProducts({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final products = await _remote.getAllProducts(
        categoryId: categoryId,
        search: search,
        page: page,
        limit: limit,
      );
      return Right(products);
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
