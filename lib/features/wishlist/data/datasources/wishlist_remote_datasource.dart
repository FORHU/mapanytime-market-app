import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:mapanytime_market_app/features/worldMap/data/models/store_model.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

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

  /// Saved stores come back in the nearby-store shape, so they parse with
  /// the map's own [StoreModel.fromJson].
  Future<List<StoreEntity>> getSavedStores() async {
    final response = await _api.get(ApiEndpoints.savedStores);
    final rawList = response is Map && response['data'] is List
        ? response['data'] as List
        : const <dynamic>[];

    return rawList
        .map((e) => StoreModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> addStore(String storeId) =>
      _api.post(ApiEndpoints.savedStores, {'storeId': storeId});

  Future<void> removeStore(String storeId) =>
      _api.delete(ApiEndpoints.savedStore(storeId));
}
