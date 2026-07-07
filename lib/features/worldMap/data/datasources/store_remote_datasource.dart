import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/worldMap/data/models/store_model.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_page.dart';

/// Talks to the remote API. Knows nothing about storage or UI. Any transport
/// failure surfaces as an AppException thrown by ApiService and is
/// translated into a typed Failure by StoreRepositoryImpl.
// ignore: one_member_abstracts
abstract class StoreRemoteDataSource {
  Future<StorePage> getNearbyStores({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
    String? categoryId,
    String? search,
    int limit,
    int offset,
  });
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  StoreRemoteDataSourceImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<StorePage> getNearbyStores({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
    String? categoryId,
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'north': north,
      'south': south,
      'east': east,
      'west': west,
      'limit': limit,
      'offset': offset,
      'lat': ?centerLat,
      'lng': ?centerLng,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final responseData = await _apiService.get(
      ApiEndpoints.storesNearby,
      query: query,
    );

    // Response envelope:
    // { data: { items: [...], total, limit, offset, hasMore } }.
    final data = responseData is Map ? responseData['data'] : null;
    final map = data is Map
        ? data.cast<String, dynamic>()
        : const <String, dynamic>{};

    final rawList = map['items'] is List
        ? map['items'] as List
        : const <dynamic>[];
    final stores = rawList
        .map((e) => StoreModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return StorePage(
      stores: stores,
      total: (map['total'] as num?)?.toInt() ?? stores.length,
      hasMore: map['hasMore'] as bool? ?? false,
      limit: (map['limit'] as num?)?.toInt() ?? limit,
      offset: (map['offset'] as num?)?.toInt() ?? offset,
    );
  }
}
