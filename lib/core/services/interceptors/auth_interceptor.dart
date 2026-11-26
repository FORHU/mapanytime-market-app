import 'package:dio/dio.dart';
import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';

/// Attaches the session token to outgoing requests, and ends the local session
/// when the server says it is over.
///
/// There is no refresh step. The API moved from JWT access/refresh tokens to
/// Better Auth sessions (API #122): one bearer token per session, lasting 30
/// days and sliding forward with use. A 401 therefore means the session is
/// gone — signed out, superseded by a sign-in on another device, or expired —
/// so the local session is cleared and the router falls back to login. (That
/// is what used to happen whenever a refresh failed; now it happens directly.)
///
/// Extends [QueuedInterceptor] so a burst of 401s clears the session once,
/// in order, rather than racing.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._storage, {this.onUnauthenticated});

  final StorageService _storage;
  final void Function()? onUnauthenticated;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path != ApiEndpoints.login) {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    // A 401 from login is a wrong password, not a dead session.
    final isLogin = err.requestOptions.path == ApiEndpoints.login;

    if (isUnauthorized && !isLogin) {
      await _storage.clearSession();
      onUnauthenticated?.call();
    }
    handler.next(err);
  }
}
