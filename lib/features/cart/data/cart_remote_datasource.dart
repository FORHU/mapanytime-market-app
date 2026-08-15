import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';

/// Thin wrapper around the cart API endpoints.
///
/// The API stores the cart in Redis keyed by the authenticated user id —
/// the bearer token in the request header identifies the user, so no
/// userId parameter is needed here.
class CartRemoteDataSource {
  const CartRemoteDataSource(this._api);

  final ApiService _api;

  /// Adds or updates a product in the server-side cart.
  /// The API upserts by (storeId, productId) so calling this with a new
  /// quantity overwrites the previous one.
  Future<void> addToCart({
    required String storeId,
    required String productId,
    required int quantity,
  }) async {
    await _api.post(ApiEndpoints.cartAdd, {
      'storeId': storeId,
      'productId': productId,
      'quantity': quantity,
    });
  }

  /// Fetches the server-side cart payload from Redis.
  Future<Map<String, dynamic>> getCart() async {
    final response = await _api.get(ApiEndpoints.cart);
    return (response is Map && response['data'] is Map)
        ? (response['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  /// Empties the server-side cart (called after order placement).
  Future<void> clearCart() async {
    await _api.delete(ApiEndpoints.cart);
  }

  /// Fetches a server-verified pricing breakdown for the cart, or just
  /// [productIds] when provided — the exact numbers checkout will charge.
  Future<CartPricing> getPricing({List<String>? productIds}) async {
    final response = await _api.post(ApiEndpoints.cartPricing, {
      if (productIds != null && productIds.isNotEmpty) 'productIds': productIds,
    });

    final data = response is Map ? response['data'] : null;
    return CartPricing.fromJson((data as Map).cast<String, dynamic>());
  }
}
