import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/worldMap/data/models/store_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI. Any transport
/// failure surfaces as an `AppException` thrown by [ApiService].
// ignore: one_member_abstracts
abstract class StoreRemoteDataSource {
  Future<List<StoreModel>> getNearbyStores({
    required double lat,
    required double lng,
  });
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  StoreRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<List<StoreModel>> getNearbyStores({
    required double lat,
    required double lng,
  }) async {
    try {
      final responseData = await _api.get(
        ApiEndpoints.storesNearby,
        query: {'lat': lat, 'lng': lng},
      );

      final rawList = responseData is Map && responseData['data'] is List
          ? responseData['data'] as List
          : const <dynamic>[];

      return rawList
          .map((e) => StoreModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on Exception catch (_) {
      // If the backend team hasn't built the endpoint yet (404),
      // just return empty
      return [];
    }
  }
}
