import 'package:mapanytime_market_web/core/errors/exceptions.dart';
import 'package:mapanytime_market_web/core/errors/failure.dart';
import 'package:mapanytime_market_web/core/services/storage_service.dart';
import 'package:mapanytime_market_web/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mapanytime_market_web/features/auth/domain/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> logout();
}

/// Coordinates the remote data source and local token storage. Catches the
/// data layer's typed exceptions and maps them to typed [Failure] values.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final StorageService _storage;

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final user = await _remote.login(email, password);
      await _storage.saveToken(user.token);
      final refreshToken = user.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(refreshToken);
      }
      return Right(user);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _storage.clearSession();
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure('Failed to clear local session: $e'));
    }
  }
}
