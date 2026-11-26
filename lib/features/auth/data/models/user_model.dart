import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';

/// Data-layer extension of [UserEntity] that knows how to (de)serialize and
/// carries the auth token returned by the API.
///
/// Backend login/register response shape:
/// ```json
/// {
///   "message": "Login successful",
///   "data": {
///     "accessToken": "...",
///     "user": { "id": "...", "email": "...", "username": "...", ... }
///   }
/// }
/// ```
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required this.token,
    super.name,
    super.avatarUrl,
    super.countryCode,
    super.onboardingCompleted,
    super.roles,
  });

  /// Parses the full API response envelope. Accepts either the wrapped
  /// `{ data: { accessToken, user } }` shape or a flat map (a cached user).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Unwrap the `data` envelope if present (login / register responses).
    final payload = json.containsKey('data')
        ? json['data'] as Map<String, dynamic>
        : json;

    final userMap = payload.containsKey('user')
        ? payload['user'] as Map<String, dynamic>
        : payload;

    final firstName = userMap['firstName'] as String? ?? '';
    final middleName = userMap['middleName'] as String? ?? '';
    final lastName = userMap['lastName'] as String? ?? '';
    final fullName = [
      firstName,
      middleName,
      lastName,
    ].where((s) => s.isNotEmpty).join(' ');

    return UserModel(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      name: userMap['name'] as String? ?? (fullName.isEmpty ? null : fullName),
      avatarUrl: (userMap['avatarUrl'] ?? userMap['avatar']) as String?,
      countryCode:
          (payload['location'] as Map?)?['country'] as String? ??
          userMap['countryCode'] as String?,
      onboardingCompleted: userMap['onboardingCompleted'] as bool? ?? false,
      roles: _parseRoles(userMap['roles']),
      // login returns `accessToken`; a cached user stores it as `token`.
      // A `refreshToken` in an older cached user is ignored (API #122).
      token: (payload['accessToken'] ?? payload['token']) as String,
    );
  }

  /// Reads roles from either backend encoding, tolerating anything else.
  ///
  /// Login sends `["BUYER"]`; `/users/me` sends the raw Prisma relation,
  /// `[{"roleName": "BUYER"}]`. A user cached before this field existed has
  /// neither. Written without casts on purpose — [UserModel.fromJson] runs
  /// inside `StorageService.readUserModel`, whose `on Exception` catch will not
  /// swallow the `TypeError` a bad cast throws, so one malformed cached blob
  /// would escape `AuthController.build()` and break app start.
  static List<String> _parseRoles(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((role) {
          if (role is String) return role;
          if (role is Map) return role['roleName'];
          return null;
        })
        .whereType<String>()
        .toList(growable: false);
  }

  /// The session's bearer token. There is no refresh token: the API issues
  /// Better Auth sessions that slide forward with use (API #122).
  final String token;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatarUrl': avatarUrl,
    'countryCode': countryCode,
    'onboardingCompleted': onboardingCompleted,
    // Must round-trip: the cached user seeds AuthController.build(), so
    // dropping roles here would leave an admin restricted until /users/me
    // returns on every launch.
    'roles': roles,
    'token': token,
  };

  @override
  List<Object?> get props => [...super.props, token];
}
