import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mapanytime_market_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';
import 'package:mapanytime_market_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:mapanytime_market_app/features/auth/domain/usecases/register_usecase.dart';

// --- Dependency wiring (Riverpod providers) ---

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(storage: ref.watch(storageServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = AuthRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return AuthRepositoryImpl(remote, ref.watch(storageServiceProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

// --- State ---

class AuthState extends Equatable {
  const AuthState({this.isLoading = false, this.user, this.error});

  final bool isLoading;
  final UserEntity? user;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({bool? isLoading, UserEntity? user, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        // Intentionally not `error ?? this.error`: passing null clears it.
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, user, error];
}

// --- Controller ---

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    final result = await ref.read(loginUseCaseProvider)(email, password);

    return result.fold(
      (failure) {
        state = AuthState(error: failure.message);
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  Future<bool> register(
    String email,
    String password, {
    String? name,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await ref
        .read(registerUseCaseProvider)(email, password, name: name);

    return result.fold(
      (failure) {
        state = AuthState(error: failure.message);
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    final result = await ref.read(authRepositoryProvider).logout();
    result.fold(
      (failure) => state = AuthState(error: failure.message),
      (_) => state = const AuthState(),
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
