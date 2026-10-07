import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';

/// Turns coordinates into a human place name ("Baguio, Benguet") via the
/// Mapbox Geocoding v6 reverse endpoint.
///
/// Uses a dedicated Dio client pointed at `api.mapbox.com` — separate from
/// the app's ApiService which targets the project backend.
class ReverseGeocodingDatasource {
  ReverseGeocodingDatasource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.mapbox.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;

  /// The city/municipality at [lat], [lng], or null when Mapbox has no match
  /// or the request fails (offline, rate-limited, ...).
  Future<String?> placeName({required double lat, required double lng}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search/geocode/v6/reverse',
        queryParameters: {
          'longitude': lng,
          'latitude': lat,
          // `place` = city / municipality — the granularity "Discover near"
          // wants (not a barangay or street).
          'types': 'place',
          'access_token': AppConfig.instance.mapboxPublicToken,
        },
      );
      final data = response.data;
      return data == null ? null : labelFrom(data);
    } on DioException catch (e) {
      debugPrint('Reverse geocoding failed: ${e.message}');
      return null;
    }
  }

  /// Builds "Place, Region" from a v6 FeatureCollection, or just "Place"
  /// when there's no region in the context.
  @visibleForTesting
  static String? labelFrom(Map<String, dynamic> json) {
    final features = json['features'];
    if (features is! List || features.isEmpty) return null;
    final feature = features.first;
    if (feature is! Map) return null;
    final props = feature['properties'];
    if (props is! Map) return null;

    final name = props['name'];
    if (name is! String || name.trim().isEmpty) return null;

    final context = props['context'];
    final region = context is Map ? context['region'] : null;
    final regionName = region is Map ? region['name'] : null;
    if (regionName is String &&
        regionName.trim().isNotEmpty &&
        regionName != name) {
      return '${name.trim()}, ${regionName.trim()}';
    }
    return name.trim();
  }
}
