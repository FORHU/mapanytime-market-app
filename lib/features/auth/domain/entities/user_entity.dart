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
    this.roles = const [],
  });

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? countryCode;
  final bool onboardingCompleted;

  /// Platform role names as the backend spells them, e.g. `BUYER`, `ADMIN`.
  ///
  /// Empty when unknown — a user cached before this field existed, or a
  /// response that omitted it. See [hasPlatformAdminRole] for why that matters.
  final List<String> roles;

  /// Mirrors `ADMIN_ROLES` on the backend.
  ///
  /// Deliberately fails closed: empty or unrecognised roles return false, so an
  /// unknown user is treated as a restricted buyer rather than waved through.
  bool get hasPlatformAdminRole =>
      roles.any(_platformAdminRoles.contains);

  static const Set<String> _platformAdminRoles = {
    'ADMIN',
    'DEVELOPER',
    'SUPER_ADMIN',
  };

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    avatarUrl,
    countryCode,
    onboardingCompleted,
    roles,
  ];
}
