import 'package:mapanytime_market_app/features/home/domain/entities/product.dart';

/// One page of catalog products from `GET /products/all` (the standard
/// `{ items, total, page, limit, totalPages }` envelope).
class ProductPage {
  const ProductPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<Product> items;
  final int page;
  final int totalPages;
  final int total;

  /// Whether a further page exists after this one.
  bool get hasMore => page < totalPages;
}
