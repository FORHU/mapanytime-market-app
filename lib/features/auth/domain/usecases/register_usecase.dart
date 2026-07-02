import 'dart:ui';
import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';

/// Registers a new buyer account.
class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(
    String email,
    String password, {
    String? name,
  }) {
    final countryCode = PlatformDispatcher.instance.locale.countryCode;
    return _repository.register(
      email.trim(),
      password,
      name: name,
      countryCode: countryCode,
      roleName: 'BUYER',
    );
  }
}
