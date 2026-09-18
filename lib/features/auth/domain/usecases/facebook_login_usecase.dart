import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';

/// A single business action. Callable like a function:
/// `facebookLoginUseCase(token)`.
class FacebookLoginUseCase {
  FacebookLoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call(String accessToken) =>
      _repository.loginWithFacebook(accessToken);
}
