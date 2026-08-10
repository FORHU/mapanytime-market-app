import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/store/data/mock_merchant_ads.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_hours.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

/// Fetches storefront data from the real backend.
///
/// Two calls are made:
///   1. GET /v1/stores/:id   → store metadata (name, hours, location …)
///   2. GET /v1/products/all?storeId=:id → active product list for that store
class StoreRemoteDataSource {
  const StoreRemoteDataSource(this._api);

  final ApiService _api;

  Future<StoreDetails> getStoreDetails(String storeId) async {
    // ── 1. Store metadata ──────────────────────────────────────────────────
    final storeResponse = await _api.get('${ApiEndpoints.storeById}/$storeId');
    final storeData =
        (storeResponse is Map ? storeResponse['data'] : null)
            as Map<dynamic, dynamic>? ??
        {};

    // ── 2. Products ────────────────────────────────────────────────────────
    final productsResponse = await _api.get(
      ApiEndpoints.allProducts,
      query: {'storeId': storeId, 'limit': 100},
    );
    final productsData =
        (productsResponse is Map ? productsResponse['data'] : null) as Map? ??
        {};
    final rawProducts = (productsData['items'] is List
        ? productsData['items'] as List<dynamic>
        : <dynamic>[]);

    final products = rawProducts.map((e) {
      final map = (e as Map).cast<String, dynamic>();
      if ((map['storeId'] as String?)?.isEmpty ?? true) {
        map['storeId'] = storeId;
      }
      return StoreProduct.fromJson(map);
    }).toList();

    // Derive category chip labels from unique product categories.
    final categoryNames = {
      'All',
      for (final p in products)
        if (p.category.isNotEmpty) p.category,
    }.toList();

    // ── 3. Build StoreDetails ─────────────────────────────────────────────
    final location = storeData['storeLocations'] as Map<String, dynamic>?;
    final rawHours = storeData['storeHours'] as List<dynamic>?;
    final parsedHours = _parseHours(rawHours);
    final category = _categoryLabel(storeData);

    return StoreDetails(
      // No hero image in the API yet — use a placeholder seeded by storeId.
      heroImageUrl: 'https://picsum.photos/seed/$storeId/800/400',
      // Reviews/ratings not yet in the API; use neutral defaults.
      rating: 0,
      ratingCount: 0,
      category: category,
      isOpen: parsedHours.isOpenNow(),
      etaLabel: _etaLabel(location),
      productCategories: categoryNames,
      products: products,
      hours: parsedHours,
      // Merchant ads not yet in the API; synthesized client-side like
      // heroImageUrl/rating above until the backend ships a real ads field.
      ads: mockMerchantAdsForStore(storeId, category: category),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _categoryLabel(Map<dynamic, dynamic> storeData) {
    final cats = storeData['categories'] as List?;
    if (cats == null || cats.isEmpty) return 'Marketplace';
    return (cats.first as Map)['name'] as String? ?? 'Marketplace';
  }

  List<StoreDayHours> _parseHours(List<dynamic>? hours) {
    if (hours == null) return const [];
    return hours.map((h) {
      final hMap = h as Map<String, dynamic>;
      return StoreDayHours(
        dayOfWeek: (hMap['dayOfWeek'] as num?)?.toInt() ?? -1,
        isClosed: hMap['isClosed'] == true,
        openMinutes: _minutesOf(hMap['openMinutes'], hMap['openTime']),
        closeMinutes: _minutesOf(hMap['closeMinutes'], hMap['closeTime']),
      );
    }).toList();
  }

  /// Store hours are minutes since midnight (`openMinutes` = 480 → 08:00).
  /// [legacy] is the pre-migration `"HH:MM"` string, kept as a fallback so a
  /// backend that has not been migrated yet still renders correctly.
  int? _minutesOf(Object? minutes, Object? legacy) {
    if (minutes is num) return minutes.toInt();
    if (legacy is String) return _parseTime(legacy);
    return null;
  }

  int? _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _etaLabel(Map<String, dynamic>? location) {
    final city = location?['city'] as String?;
    return city != null ? 'Pickup in $city' : 'Available for pickup';
  }
}
