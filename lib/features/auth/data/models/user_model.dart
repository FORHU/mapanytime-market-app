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
      // login/register returns `accessToken`; refresh returns `accessToken` too.
      token: (payload['accessToken'] ?? payload['token']) as String,
      refreshToken: payload['refreshToken'] as String?,
    );
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
    'token': token,
    'refreshToken': refreshToken,
  };

  @override
  List<Object?> get props => [...super.props, token, refreshToken];
}
