import 'package:dio/dio.dart';

import '../config/app_config.dart';

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
  ApiService({Dio? dio})
      : client = dio ??
            Dio(
              BaseOptions(
                // Base URL comes from the active environment (dev/prod).
                baseUrl: AppConfig.instance.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ) {
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
