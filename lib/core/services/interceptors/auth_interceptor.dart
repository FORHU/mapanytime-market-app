import 'package:dio/dio.dart';

import 'package:flutter_template/core/services/storage_service.dart';

/// Intercepts outgoing requests to attach the Bearer token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final StorageService _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return super.onRequest(options, handler);
  }
}
