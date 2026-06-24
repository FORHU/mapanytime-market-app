import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';

/// Registers a new buyer account.
class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call(
    String email,
    String password,
    String username, {
    String? name,
  }) =>
      _repository.register(email.trim(), password, username.trim(), name: name);
}
