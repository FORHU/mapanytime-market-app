import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';

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

  /// Empties the server-side cart (called after order placement).
  Future<void> clearCart() async {
    await _api.delete(ApiEndpoints.cart);
  }
}
