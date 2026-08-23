import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/wishlist/domain/entities/wishlist_item.dart';

class WishlistRemoteDataSource {
  const WishlistRemoteDataSource(this._api);

  final ApiService _api;

  Future<List<WishlistItem>> getWishlist() async {
    final response = await _api.get(ApiEndpoints.wishlist);
    final data = response is Map ? response['data'] : null;
    final rawItems = data is Map && data['items'] is List
        ? data['items'] as List
        : const <dynamic>[];

    return rawItems
        .map(
          (e) => WishlistItem.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> add(String productId) =>
      _api.post(ApiEndpoints.wishlistItems, {'productId': productId});

  Future<void> remove(String productId) =>
      _api.delete(ApiEndpoints.wishlistItem(productId));
}
