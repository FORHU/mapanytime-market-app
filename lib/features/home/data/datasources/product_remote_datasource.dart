import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/product.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/product_page.dart';

/// Fetches the buyer catalog from `GET /products/all`. An optional `categoryId`
/// narrows the results to that category and all of its descendants (the backend
/// expands a parent category to its children).
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._api);

  final ApiService _api;

  Future<ProductPage> getAllProducts({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final responseData = await _api.get(
      ApiEndpoints.allProducts,
      query: {
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );

    // Envelope: { ..., data: { items: [...], total, page, totalPages } }.
    final data = responseData is Map ? responseData['data'] : null;
    final rawList = (data is Map && data['items'] is List)
        ? data['items'] as List
        : const <dynamic>[];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .where((p) => p.id.isNotEmpty)
        .toList();

    int intOf(String key, int fallback) {
      final v = data is Map ? data[key] : null;
      return v is num ? v.toInt() : fallback;
    }

    return ProductPage(
      items: items,
      page: intOf('page', page),
      totalPages: intOf('totalPages', 1),
      total: intOf('total', items.length),
    );
  }

  Product _fromJson(Map<String, dynamic> m) {
    final store = m['store'];
    final file = m['productFile'];
    final category = m['category'];

    return Product(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0,
      storeId: m['storeId'] as String? ??
          (store is Map ? store['id'] as String? : null),
      storeName: store is Map ? store['storeName'] as String? : null,
      imageUrl: file is Map ? file['fileUrl'] as String? : null,
      categoryName: category is Map ? category['name'] as String? : null,
    );
  }
}
