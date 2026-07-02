import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/worldMap/data/repositories/category_repository.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_category.dart';

/// Fetches the parent categories used for the map filter chips.
class GetParentCategoriesUseCase {
  GetParentCategoriesUseCase(this.repository);

  final CategoryRepository repository;

  Future<Either<Failure, List<StoreCategory>>> call() {
    return repository.getParentCategories();
  }
}
