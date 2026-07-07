import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/repositories/category_repository.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/category_tree.dart';

/// Fetches root categories with their nested children for the Home drill-down
/// filter.
class GetCategoryTreeUseCase {
  GetCategoryTreeUseCase(this.repository);

  final CategoryRepository repository;

  Future<Either<Failure, List<CategoryTree>>> call() {
    return repository.getCategoryTree();
  }
}
