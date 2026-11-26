import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    mockApi = MockApiService();
    dataSource = AuthRemoteDataSourceImpl(mockApi);
  });

  const tAccessToken = 'test-session-token-123';
  const tUserResponse = {
    'statusCode': 200,
    'message': 'Success',
    'data': {
      'accessToken': tAccessToken,
      'user': {
        'id': 'user-123',
        'email': 'buyer@example.com',
        'firstName': 'Juan',
        'lastName': 'Dela Cruz',
        'roles': ['BUYER'],
      },
    },
  };

  group('AuthRemoteDataSourceImpl.login', () {
    const tEmail = 'buyer@example.com';
    const tPassword = 'Password123!';

    test(
      'posts to /auth/login with BUYER role and returns UserModel',
      () async {
        when(
          () => mockApi.post(ApiEndpoints.login, {
            'email': tEmail,
            'password': tPassword,
            'roleName': 'BUYER',
          }),
        ).thenAnswer((_) async => tUserResponse);

        final user = await dataSource.login(tEmail, tPassword);

        expect(user.id, 'user-123');
        expect(user.email, tEmail);
        expect(user.name, 'Juan Dela Cruz');
        expect(user.token, tAccessToken);
        expect(user.roles, ['BUYER']);
        verify(
          () => mockApi.post(ApiEndpoints.login, {
            'email': tEmail,
            'password': tPassword,
            'roleName': 'BUYER',
          }),
        ).called(1);
      },
    );
  });

  group('AuthRemoteDataSourceImpl.loginWithFacebook', () {
    const tFacebookToken = 'fb-access-token-xyz';

    test('posts to /auth/facebook and returns UserModel', () async {
      when(
        () => mockApi.post(ApiEndpoints.facebookLogin, {
          'accessToken': tFacebookToken,
        }),
      ).thenAnswer((_) async => tUserResponse);

      final user = await dataSource.loginWithFacebook(tFacebookToken);

      expect(user.id, 'user-123');
      expect(user.email, 'buyer@example.com');
      expect(user.token, tAccessToken);
      verify(
        () => mockApi.post(ApiEndpoints.facebookLogin, {
          'accessToken': tFacebookToken,
        }),
      ).called(1);
    });
  });

  group('AuthRemoteDataSourceImpl.loginWithGoogle', () {
    const tGoogleToken = 'google-id-token-abc';

    test('posts to /auth/google and returns UserModel', () async {
      when(
        () => mockApi.post(ApiEndpoints.googleLogin, {
          'idToken': tGoogleToken,
        }),
      ).thenAnswer((_) async => tUserResponse);

      final user = await dataSource.loginWithGoogle(tGoogleToken);

      expect(user.id, 'user-123');
      expect(user.email, 'buyer@example.com');
      expect(user.token, tAccessToken);
      verify(
        () => mockApi.post(ApiEndpoints.googleLogin, {
          'idToken': tGoogleToken,
        }),
      ).called(1);
    });
  });

  group('AuthRemoteDataSourceImpl.register', () {
    const tEmail = 'newbuyer@example.com';
    const tPassword = 'Password123!';
    const tFirst = 'Maria';
    const tLast = 'Santos';

    test('posts JSON fields when profile is null', () async {
      when(
        () => mockApi.post(ApiEndpoints.register, any()),
      ).thenAnswer(
        (_) async => {'statusCode': 201, 'message': 'Registration successful'},
      );

      await dataSource.register(
        tEmail,
        tPassword,
        firstName: tFirst,
        lastName: tLast,
        middleName: 'Clara',
        countryCode: '+63',
      );

      final captured =
          verify(
                () => mockApi.post(ApiEndpoints.register, captureAny()),
              ).captured.single
              as Map<String, dynamic>;

      expect(captured['email'], tEmail);
      expect(captured['password'], tPassword);
      expect(captured['firstName'], tFirst);
      expect(captured['lastName'], tLast);
      expect(captured['middleName'], 'Clara');
      expect(captured['countryCode'], '+63');
      expect(captured['roleName'], 'BUYER');
    });

    test(
      'posts FormData with multipart validId photo when profile is provided',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('auth_test_');
        final tempFile = File('${tempDir.path}/test_id.png')
          ..writeAsStringSync('dummy content');

        try {
          final profile = RegistrationProfile(
            phoneNumber: '+639171234567',
            dateOfBirth: DateTime(1995, 8, 20),
            sex: Sex.female,
            address: '456 Rizal St, Manila',
            idType: IdType.philsys,
            idNumber: '1111-2222-3333-4444',
            idPhotoPath: tempFile.path,
          );

          when(
            () => mockApi.post(ApiEndpoints.register, any()),
          ).thenAnswer(
            (_) async => {
              'statusCode': 201,
              'message': 'Registration successful',
            },
          );

          await dataSource.register(
            tEmail,
            tPassword,
            firstName: tFirst,
            lastName: tLast,
            profile: profile,
          );

          final captured = verify(
            () => mockApi.post(ApiEndpoints.register, captureAny()),
          ).captured.single;

          expect(captured, isA<FormData>());
          final formData = captured as FormData;
          expect(
            formData.fields.any((f) => f.key == 'email' && f.value == tEmail),
            isTrue,
          );
          expect(
            formData.fields.any(
              (f) => f.key == 'dateOfBirth' && f.value == '1995-08-20',
            ),
            isTrue,
          );
          expect(
            formData.fields.any((f) => f.key == 'sex' && f.value == 'FEMALE'),
            isTrue,
          );
          expect(
            formData.fields.any(
              (f) => f.key == 'phoneNumber' && f.value == '+639171234567',
            ),
            isTrue,
          );
          expect(
            formData.fields.any(
              (f) => f.key == 'validIdType' && f.value == 'PHILSYS',
            ),
            isTrue,
          );
          expect(
            formData.fields.any(
              (f) =>
                  f.key == 'validIdNumber' && f.value == '1111-2222-3333-4444',
            ),
            isTrue,
          );
          expect(
            formData.files.any(
              (f) => f.key == 'validId' && f.value.filename == 'valid-id.png',
            ),
            isTrue,
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );
  });

  group('AuthRemoteDataSourceImpl.checkAuth', () {
    const tToken = 'session-token-456';

    test('calls /users/me and injects token into wrapped data', () async {
      when(
        () => mockApi.get(ApiEndpoints.me),
      ).thenAnswer(
        (_) async => {
          'data': {
            'id': 'user-123',
            'email': 'buyer@example.com',
            'roles': ['BUYER'],
          },
        },
      );

      final user = await dataSource.checkAuth(tToken);

      expect(user.id, 'user-123');
      expect(user.token, tToken);
      verify(() => mockApi.get(ApiEndpoints.me)).called(1);
    });

    test('calls /users/me and injects token into flat data', () async {
      when(
        () => mockApi.get(ApiEndpoints.me),
      ).thenAnswer(
        (_) async => {
          'id': 'user-123',
          'email': 'buyer@example.com',
          'roles': ['BUYER'],
        },
      );

      final user = await dataSource.checkAuth(tToken);

      expect(user.id, 'user-123');
      expect(user.token, tToken);
      verify(() => mockApi.get(ApiEndpoints.me)).called(1);
    });
  });

  group('AuthRemoteDataSourceImpl.logout', () {
    test('posts empty map to /auth/logout', () async {
      when(
        () => mockApi.post(ApiEndpoints.logout, any()),
      ).thenAnswer((_) async => {'statusCode': 200, 'message': 'Logged out'});

      await dataSource.logout();

      verify(
        () => mockApi.post(ApiEndpoints.logout, <String, dynamic>{}),
      ).called(1);
    });
  });

  group('AuthRemoteDataSourceImpl.passwordReset', () {
    test('requestPasswordReset posts email to /auth/forgot-password', () async {
      when(
        () => mockApi.post(ApiEndpoints.forgotPassword, any()),
      ).thenAnswer((_) async => {'message': 'Check your email'});

      await dataSource.requestPasswordReset('buyer@example.com');

      verify(
        () => mockApi.post(ApiEndpoints.forgotPassword, {
          'email': 'buyer@example.com',
        }),
      ).called(1);
    });

    test(
      'resetPassword posts email, code, and newPassword to /auth/reset-password',
      () async {
        when(
          () => mockApi.post(ApiEndpoints.resetPassword, any()),
        ).thenAnswer((_) async => {'message': 'Password has been reset'});

        await dataSource.resetPassword(
          'buyer@example.com',
          '1234',
          'NewSecret123!',
        );

        verify(
          () => mockApi.post(ApiEndpoints.resetPassword, {
            'email': 'buyer@example.com',
            'code': '1234',
            'newPassword': 'NewSecret123!',
          }),
        ).called(1);
      },
    );
  });
}
