import 'package:fpdart/fpdart.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';

class RefreshAuthUseCase {
  const RefreshAuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> execute() {
    return _repository.refreshAuth();
  }
}
