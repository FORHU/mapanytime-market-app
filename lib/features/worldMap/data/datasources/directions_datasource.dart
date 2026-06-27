import 'package:dio/dio.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Calls the Mapbox Directions v5 REST API to get a driving route between two
/// geographic points. Returns a list of Positions that follow the actual
/// road network, ready to be fed into a LineString for map rendering.
///
/// Uses a dedicated Dio client pointed at `api.mapbox.com` — separate from
/// the app's ApiService which targets the project backend.
class DirectionsDatasource {
  DirectionsDatasource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.mapbox.com',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  final Dio _dio;

  /// Fetches a driving route from [origin] to [destination].
  ///
  /// Returns an ordered list of [Position]s along the route, or an empty list
  /// if the API returns no route (e.g. origin == destination, unreachable).
  Future<List<Position>> getRoute({
    required Position origin,
    required Position destination,
  }) async {
    final token = AppConfig.instance.mapboxPublicToken;

    // Mapbox Directions coordinate format: {lng},{lat}
    final originStr = '${origin.lng},${origin.lat}';
    final destinationStr = '${destination.lng},${destination.lat}';
    final coordinates = '$originStr;$destinationStr';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/directions/v5/mapbox/driving/$coordinates',
        queryParameters: {
          'geometries': 'geojson',
          'overview': 'full',
          'access_token': token,
        },
      );

      final data = response.data;
      if (data == null) return [];

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];

      final geometry = (routes.first as Map)['geometry'] as Map?;
      if (geometry == null) return [];

      final coords = geometry['coordinates'] as List?;
      if (coords == null || coords.isEmpty) return [];

      // Each coordinate from Mapbox is [lng, lat]
      return coords.map((c) {
        final pair = c as List;
        return Position(
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        );
      }).toList();
    } on DioException catch (e) {
      // Non-fatal — fall back to caller handling an empty list
      throw Exception('Directions API error: ${e.message}');
    }
  }
}
