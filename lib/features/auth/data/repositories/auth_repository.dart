import '../../../../core/services/storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
}

/// Coordinates the remote data source and local token storage.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final StorageService _storage;

  @override
  Future<UserEntity> login(String email, String password) async {
    final user = await _remote.login(email, password);
    await _storage.saveToken(user.token);
    return user;
  }

  @override
  Future<void> logout() => _storage.clearToken();
}
