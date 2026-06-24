import 'package:equatable/equatable.dart';

/// Pure domain object — no JSON, no framework types. Equatable gives value
/// equality so two users with the same fields compare equal.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.name,
    this.avatarUrl,
    this.onboardingCompleted = false,
  });

  final String id;
  final String email;
  final String username;
  final String? name;
  final String? avatarUrl;
  final bool onboardingCompleted;

  @override
  List<Object?> get props =>
      [id, email, username, name, avatarUrl, onboardingCompleted];
}
