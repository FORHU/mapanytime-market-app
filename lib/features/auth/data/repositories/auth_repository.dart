import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> logout();
}

/// Coordinates the remote data source and local token storage.
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
      return Right(user);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _storage.clearToken();
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure('Failed to clear local token: $e'));
    }
  }
}
