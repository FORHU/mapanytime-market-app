import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_template/features/auth/data/models/user_model.dart';
import 'package:flutter_template/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockStorageService extends Mock implements StorageService {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockStorageService mockStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockStorage = MockStorageService();
    repository = AuthRepositoryImpl(mockRemote, mockStorage);
  });

  group('AuthRepositoryImpl.login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUser = UserModel(
      id: '1',
      email: tEmail,
      name: 'Test',
      token: 'fake-jwt-token',
    );

    test('returns Right(user) and persists the token on success', () async {
      // Arrange
      when(
        () => mockRemote.login(tEmail, tPassword),
      ).thenAnswer((_) async => tUser);
      when(() => mockStorage.saveToken(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.login(tEmail, tPassword);

      // Assert
      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), tUser);
      verify(() => mockStorage.saveToken('fake-jwt-token')).called(1);
    });

    test('returns Left(ServerFailure) when the data source throws '
        'ApiException', () async {
      // Arrange
      when(
        () => mockRemote.login(tEmail, tPassword),
      ).thenThrow(ApiException('Invalid email or password'));

      // Act
      final result = await repository.login(tEmail, tPassword);

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ServerFailure>());
      expect(failure!.message, 'Invalid email or password');
      verifyNever(() => mockStorage.saveToken(any()));
    });

    test('returns Left(ServerFailure) on an unexpected error', () async {
      // Arrange
      when(
        () => mockRemote.login(tEmail, tPassword),
      ).thenThrow(Exception('boom'));

      // Act
      final result = await repository.login(tEmail, tPassword);

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('clears the token and returns Right(null)', () async {
      // Arrange
      when(() => mockStorage.clearToken()).thenAnswer((_) async {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockStorage.clearToken()).called(1);
    });

    test('returns Left(CacheFailure) when clearing the token throws', () async {
      // Arrange
      when(() => mockStorage.clearToken()).thenThrow(Exception('disk error'));

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });
}
