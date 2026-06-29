import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/worldMap/data/models/store_model.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Talks to the remote API. Knows nothing about storage or UI. Any transport
/// failure surfaces as an AppException thrown by ApiService and is
/// translated into a typed Failure by StoreRepositoryImpl.
// ignore: one_member_abstracts
abstract class StoreRemoteDataSource {
  Future<List<StoreEntity>> getNearbyStores({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
  });
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  StoreRemoteDataSourceImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<List<StoreEntity>> getNearbyStores({
    required double north,
    required double south,
    required double east,
    required double west,
    double? centerLat,
    double? centerLng,
  }) async {
    final query = <String, dynamic>{
      'north': north,
      'south': south,
      'east': east,
      'west': west,
      // Pass the center point so the API computes precise distances.
      // Falls back to bounding-box midpoint server-side if omitted.
      'lat': ?centerLat,
      'lng': ?centerLng,
    };

    final responseData = await _apiService.get(
      ApiEndpoints.storesNearby,
      query: query,
    );

    final rawList = responseData is Map && responseData['data'] is List
        ? responseData['data'] as List
        : const <dynamic>[];

    return rawList
        .map((e) => StoreModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
