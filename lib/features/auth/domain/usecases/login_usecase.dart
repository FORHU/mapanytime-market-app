import '../../data/repositories/auth_repository.dart';
import '../entities/user_entity.dart';

/// A single business action. Callable like a function: `loginUseCase(e, p)`.
class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call(String email, String password) =>
      _repository.login(email.trim(), password);
}
