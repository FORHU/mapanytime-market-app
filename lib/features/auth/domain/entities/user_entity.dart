import 'package:equatable/equatable.dart';

/// Pure domain object — no JSON, no framework types. Equatable gives value
/// equality so two users with the same fields compare equal.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.countryCode,
    this.onboardingCompleted = false,
  });

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? countryCode;
  final bool onboardingCompleted;

    @override
  List<Object?> get props =>
      [id, email, name, avatarUrl, countryCode, onboardingCompleted];
}
