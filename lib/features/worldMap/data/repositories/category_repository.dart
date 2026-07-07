import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/category_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/category_tree.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_category.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class CategoryRepository {
  Future<Either<Failure, List<StoreCategory>>> getParentCategories();

  /// Root categories with their nested children (drill-down filter).
  Future<Either<Failure, List<CategoryTree>>> getCategoryTree();
}

/// Fetches categories from the remote data source and maps the data layer's
/// typed exceptions into typed [Failure] values. Errors are returned, never
/// thrown or silently swallowed.
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._remote);

  final CategoryRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<StoreCategory>>> getParentCategories() async {
    try {
      final categories = await _remote.getParentCategories();
      return Right(categories);
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

  @override
  Future<Either<Failure, List<CategoryTree>>> getCategoryTree() async {
    try {
      final tree = await _remote.getCategoryTree();
      return Right(tree);
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
