import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';

/// Serves canned responses so the template runs with **no backend**.
///
/// Added to Dio only when `AppConfig.instance.useMock` is true. Because it
/// lives in the Dio pipeline, the real `ApiService` code path is still fully
/// exercised — set `USE_MOCK=false` once your backend is ready and nothing
/// else has to change.
class MockInterceptor extends Interceptor {
  static const Duration _latency = Duration(milliseconds: 600);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(_latency);
    final path = options.path;
    final body = _asMap(options.data);

    switch (path) {
      case ApiEndpoints.login:
        final email = (body['email'] as String? ?? '').trim();
        final password = body['password'] as String? ?? '';
        if (password.length < 6) {
          handler.reject(
            _error(options, 401, 'Invalid email or password'),
          );
          return;
        }
        handler.resolve(
          _ok(options, {
            'id': '1',
            'email': email,
            'name': email.split('@').first,
            'token': 'mock-access-token',
            'refreshToken': 'mock-refresh-token',
          }),
        );
      case ApiEndpoints.refresh:
        handler.resolve(
          _ok(options, {
            'token': 'mock-access-token',
            'refreshToken': 'mock-refresh-token',
          }),
        );
      case ApiEndpoints.logout:
        handler.resolve(_ok(options, {'success': true}));
      case ApiEndpoints.users:
        handler.resolve(
          _ok(options, {
            'data': [
              {'id': '1', 'name': 'Ada Lovelace'},
              {'id': '2', 'name': 'Alan Turing'},
            ],
          }),
        );
      case ApiEndpoints.storesNearby:
        handler.resolve(_ok(options, _nearbyStores));
      default:
        handler.reject(_error(options, 404, 'Unknown endpoint: $path'));
    }
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  Response<dynamic> _ok(RequestOptions options, Object data) =>
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: data,
      );

  /// Canned stores served while the backend `/stores/nearby` API is unbuilt.
  /// Coordinates centre on Jakarta to match the controller's query origin.
  static const List<Map<String, dynamic>> _nearbyStores = [
    {
      'id': '1',
      'name': 'MapAnytime Central',
      'lat': -6.2088,
      'lng': 106.8456,
      'distance': 0.5,
    },
    {
      'id': '2',
      'name': 'MapAnytime North',
      'lat': -6.2000,
      'lng': 106.8500,
      'distance': 1.2,
    },
    {
      'id': '3',
      'name': 'MapAnytime South',
      'lat': -6.2150,
      'lng': 106.8400,
      'distance': 2.0,
    },
    {
      'id': '4',
      'name': 'MapAnytime East',
      'lat': -6.2050,
      'lng': 106.8600,
      'distance': 1.8,
    },
    {
      'id': '5',
      'name': 'MapAnytime West',
      'lat': -6.2100,
      'lng': 106.8300,
      'distance': 2.5,
    },
  ];

  DioException _error(RequestOptions options, int status, String message) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: {'message': message},
        ),
      );
}
