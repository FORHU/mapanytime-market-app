import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

/// One saved product. Wraps [StoreProduct] — the same entity the rest of the
/// app already uses for product cards/detail — rather than a separate
/// product shape just for this screen.
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.product,
    this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final productJson = (json['product'] as Map?)?.cast<String, dynamic>();
    return WishlistItem(
      id: json['id'] as String? ?? '',
      // FIXME: multiple rows with a deleted/missing product all fall back to
      // id: '', which collapses in savedProductIdsProvider's Set and produces
      // a malformed DELETE (no id) if remove('') is ever called on one.
      product: productJson != null
          ? StoreProduct.fromJson(productJson)
          : const StoreProduct(
              id: '',
              name: 'Unknown product',
              imageUrl: '',
              price: 0,
              description: '',
              category: 'Other',
            ),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// The `WishlistItems` row id (not the product id) — needed nowhere yet,
  /// kept for parity with the API response.
  final String id;
  final StoreProduct product;
  final DateTime? createdAt;
}
