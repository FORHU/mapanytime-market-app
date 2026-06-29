import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

/// Display-level details for a storefront, supplementing the lean
/// `StoreEntity` from the map API with mock presentation data.
class StoreDetails {
  const StoreDetails({
    required this.heroImageUrl,
    required this.rating,
    required this.ratingCount,
    required this.category,
    required this.isOpen,
    required this.etaLabel,
    required this.productCategories,
    required this.products,
  });

  final String heroImageUrl;
  final double rating;
  final int ratingCount;
  final String category;
  final bool isOpen;
  final String etaLabel;
  final List<String> productCategories;
  final List<StoreProduct> products;
}
