import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_category.dart';

/// Fetches categories from the API. With no `parentId`, `GET /categories`
/// returns the root (parent) categories used for the map filter chips.
class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._api);

  final ApiService _api;

  Future<List<StoreCategory>> getParentCategories() async {
    final responseData = await _api.get(ApiEndpoints.categories);

    // Envelope: { status, statusCode, data: [ { id, name, ... }, ... ] }.
    final data = responseData is Map ? responseData['data'] : null;
    final rawList = data is List ? data : const <dynamic>[];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => StoreCategory(
            id: m['id'] as String? ?? '',
            name: m['name'] as String? ?? '',
          ),
        )
        .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
        .toList();
  }
}
