import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/interceptors/auth_interceptor.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/logger.dart';

/// Thin wrapper around [Dio].
///
/// NOTE: To keep this template runnable with no backend, [post] fakes the
/// `/login` response. Replace the faked block with a real call:
///
/// ```dart
/// final res = await client.post(path, data: body);
/// return res.data as Map<String, dynamic>;
/// ```
class ApiService {
  ApiService({required StorageService storage, Dio? dio})
    : client =
          dio ??
          Dio(
            BaseOptions(
              // Base URL comes from the active environment (dev/prod).
              baseUrl: AppConfig.instance.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          ) {
    // 1. Inject Auth Bearer tokens
    client.interceptors.add(AuthInterceptor(storage));

    // 2. Smart Retry for unstable networks
    client.interceptors.add(
      RetryInterceptor(
        dio: client,
        logPrint: appLogger.w, // Prints retry attempts using AppLogger
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );

    // 3. Logger (only in dev)
    if (AppConfig.instance.enableLogging) {
      client.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  /// Exposed so interceptors/tests can configure or replace the client.
  final Dio client;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    // --- FAKE backend (remove once a real API exists) ---
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (path == '/login') {
      final email = (body['email'] as String? ?? '').trim();
      final password = body['password'] as String? ?? '';
      if (password.length < 6) {
        throw ApiException('Invalid email or password');
      }
      return {
        'id': '1',
        'email': email,
        'name': email.split('@').first,
        'token': 'fake-jwt-token',
      };
    }

    throw ApiException('Unknown endpoint: $path');
    // --- end FAKE backend ---
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
