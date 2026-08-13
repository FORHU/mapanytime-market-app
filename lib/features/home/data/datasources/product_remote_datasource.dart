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

    // Envelope: { ..., data: { items: [...], meta: { total, page, limit,
    // totalPages } } }. Older responses put the counters directly on `data`,
    // so fall back to that when `meta` is absent.
    final data = responseData is Map ? responseData['data'] : null;
    final rawList = (data is Map && data['items'] is List)
        ? data['items'] as List
        : const <dynamic>[];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .where((p) => p.id.isNotEmpty)
        .toList();

    final meta = (data is Map && data['meta'] is Map) ? data['meta'] : data;

    int intOf(String key, int fallback) {
      final v = meta is Map ? meta[key] : null;
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
    final category = m['category'];

    return Product(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      price: _priceOf(m['price']),
      storeId:
          m['storeId'] as String? ??
          (store is Map ? store['id'] as String? : null),
      storeName: store is Map ? store['storeName'] as String? : null,
      imageUrl: _imageUrlOf(m),
      categoryName: category is Map ? category['name'] as String? : null,
    );
  }

  /// Prisma serializes `Decimal` columns as strings (`"1950"`), so a plain
  /// `as num` cast blows up the whole page. Accept both shapes.
  double _priceOf(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  /// The catalog returns the primary image as
  /// `productImages: [{ file: { path } }]`.
  String? _imageUrlOf(Map<String, dynamic> m) {
    final images = m['productImages'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      final file = first is Map ? first['file'] : null;
      if (file is Map) {
        return (file['url'] ?? file['path'] ?? file['fileUrl']) as String?;
      }
    }
    // Legacy/mock shape.
    final file = m['productFile'];
    return file is Map ? file['fileUrl'] as String? : null;
  }
}
