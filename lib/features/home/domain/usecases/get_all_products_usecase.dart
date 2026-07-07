import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/home/data/repositories/product_repository.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/product_page.dart';

/// Fetches a page of the buyer catalog for the Home grid, optionally filtered
/// by a category.
class GetAllProductsUseCase {
  GetAllProductsUseCase(this.repository);

  final ProductRepository repository;

  Future<Either<Failure, ProductPage>> call({
    required int page,
    required int limit,
    String? categoryId,
    String? search,
  }) {
    return repository.getAllProducts(
      categoryId: categoryId,
      search: search,
      page: page,
      limit: limit,
    );
  }
}
