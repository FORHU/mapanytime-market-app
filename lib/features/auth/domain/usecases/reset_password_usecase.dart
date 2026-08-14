import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';

/// Verifies the reset code and sets a new password.
class ResetPasswordUseCase {
  ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(
    String email,
    String code,
    String newPassword,
  ) => _repository.resetPassword(email, code, newPassword);
}
