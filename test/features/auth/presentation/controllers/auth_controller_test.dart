import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUser = UserEntity(
      id: '1',
      email: tEmail,
      username: 'testuser',
      name: 'Test',
    );

    test('initial state is AuthState()', () {
      final state = container.read(authControllerProvider);
      expect(state, const AuthState());
      expect(state.isAuthenticated, false);
    });

    test('login success updates state with user and returns true', () async {
      when(
        () => mockRepository.login(tEmail, tPassword),
      ).thenAnswer((_) async => const Right(tUser));

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login(tEmail, tPassword);

      expect(result, true);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, false);
      expect(state.user, tUser);
      expect(state.error, isNull);
      verify(() => mockRepository.login(tEmail, tPassword)).called(1);
    });

    test('login failure updates state with error and returns false', () async {
      const tFailure = ServerFailure('Invalid credentials');
      when(
        () => mockRepository.login(tEmail, tPassword),
      ).thenAnswer((_) async => const Left(tFailure));

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login(tEmail, tPassword);

      expect(result, false);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, false);
      expect(state.user, isNull);
      expect(state.error, tFailure.message);
      verify(() => mockRepository.login(tEmail, tPassword)).called(1);
    });
  });
}
