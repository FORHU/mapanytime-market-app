import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/recommendations/domain/entities/nearby_deal.dart';

/// Fetches active discount ads across nearby stores for the "Today's Deals"
/// rail. Same bounding-box shape as the world map's nearby-stores call.
class DealsRemoteDataSource {
  const DealsRemoteDataSource(this._api);

  final ApiService _api;

  Future<List<NearbyDeal>> getNearbyDeals({
    required double north,
    required double south,
    required double east,
    required double west,
    double? lat,
    double? lng,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiEndpoints.merchantAdsNearby,
      query: {
        'north': north,
        'south': south,
        'east': east,
        'west': west,
        'lat': ?lat,
        'lng': ?lng,
        'limit': limit,
      },
    );

    final rawList = response is Map && response['data'] is List
        ? response['data'] as List
        : const <dynamic>[];

    return rawList
        .map((e) => NearbyDeal.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
