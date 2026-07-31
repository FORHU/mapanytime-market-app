import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
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
    final hours = storeData['storeHours'] as List<dynamic>?;

    return StoreDetails(
      // No hero image in the API yet — use a placeholder seeded by storeId.
      heroImageUrl: 'https://picsum.photos/seed/$storeId/800/400',
      // Reviews/ratings not yet in the API; use neutral defaults.
      rating: 0,
      ratingCount: 0,
      category: _categoryLabel(storeData),
      isOpen: _isOpenNow(hours),
      etaLabel: _etaLabel(location),
      productCategories: categoryNames,
      products: products,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _categoryLabel(Map<dynamic, dynamic> storeData) {
    final cats = storeData['categories'] as List?;
    if (cats == null || cats.isEmpty) return 'Marketplace';
    return (cats.first as Map)['name'] as String? ?? 'Marketplace';
  }

  bool _isOpenNow(List<dynamic>? hours) {
    if (hours == null || hours.isEmpty) return true;
    final now = DateTime.now();
    // dayOfWeek: Prisma uses 0=Sun … 6=Sat; DateTime.weekday 1=Mon … 7=Sun.
    final dow = now.weekday % 7; // converts to 0=Sun … 6=Sat
    for (final h in hours) {
      final hMap = h as Map<String, dynamic>;
      if (hMap['dayOfWeek'] == dow) {
        if (hMap['isClosed'] == true) return false;
        final open = _parseTime(hMap['openTime'] as String?);
        final close = _parseTime(hMap['closeTime'] as String?);
        if (open != null && close != null) {
          final nowMins = now.hour * 60 + now.minute;
          return nowMins >= open && nowMins < close;
        }
      }
    }
    return true;
  }

  int? _parseTime(String? t) {
    if (t == null) return null;
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
