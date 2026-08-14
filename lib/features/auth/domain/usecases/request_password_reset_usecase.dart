import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';

/// Sends a one-time reset code to the given email.
class RequestPasswordResetUseCase {
  RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(String email) =>
      _repository.requestPasswordReset(email);
}
