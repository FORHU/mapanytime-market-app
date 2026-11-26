import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/interceptors/auth_interceptor.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

/// Answers every request with [statusCode] and records what was sent.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode);

  final int statusCode;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'message': 'status $statusCode'}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// The API issues Better Auth sessions (API #122): one bearer token, no refresh
/// token, and `/auth/refresh-token` always answers 401. So a 401 ends the
/// session — the interceptor must not try to refresh or retry.
void main() {
  late MockStorageService storage;
  late int unauthenticatedCalls;

  setUp(() {
    storage = MockStorageService();
    unauthenticatedCalls = 0;
    when(storage.readToken).thenAnswer((_) async => 'session-token.sig');
    when(storage.clearSession).thenAnswer((_) async {});
  });

  ({Dio dio, _RecordingAdapter adapter}) client(int status) {
    final adapter = _RecordingAdapter(status);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(
          storage,
          onUnauthenticated: () => unauthenticatedCalls++,
        ),
      );
    return (dio: dio, adapter: adapter);
  }

  test('attaches the session token as a bearer token', () async {
    final c = client(200);

    await c.dio.get<dynamic>('/orders');

    expect(
      c.adapter.requests.single.headers['Authorization'],
      'Bearer session-token.sig',
    );
  });

  test(
    'a 401 ends the session: clears it, once, with no refresh or retry',
    () async {
      final c = client(401);

      await expectLater(
        c.dio.get<dynamic>('/orders'),
        throwsA(isA<DioException>()),
      );

      expect(c.adapter.requests, hasLength(1));
      expect(c.adapter.requests.single.path, '/orders');
      verify(storage.clearSession).called(1);
      expect(unauthenticatedCalls, 1);
    },
  );

  test('a 401 from login is a wrong password, not a dead session', () async {
    final c = client(401);

    await expectLater(
      c.dio.post<dynamic>(ApiEndpoints.login, data: <String, dynamic>{}),
      throwsA(isA<DioException>()),
    );

    verifyNever(storage.clearSession);
    expect(unauthenticatedCalls, 0);
    expect(c.adapter.requests.single.headers['Authorization'], isNull);
  });

  test('other errors leave the session alone', () async {
    final c = client(403);

    await expectLater(
      c.dio.get<dynamic>('/admin'),
      throwsA(isA<DioException>()),
    );

    verifyNever(storage.clearSession);
    expect(unauthenticatedCalls, 0);
  });
}
