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
///     "refreshToken": "...",
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
    this.refreshToken,
  });

  /// Parses the full API response envelope. Accepts either the wrapped
  /// `{ data: { accessToken, user } }` shape or a flat map (for refresh).
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
      // login/register returns `accessToken`; refresh returns `accessToken` too.
      token: (payload['accessToken'] ?? payload['token']) as String,
      refreshToken: payload['refreshToken'] as String?,
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

  /// Short-lived access token (bearer).
  final String token;

  /// Long-lived token used to obtain a new access token.
  final String? refreshToken;

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
    'refreshToken': refreshToken,
  };

  @override
  List<Object?> get props => [...super.props, token, refreshToken];
}
