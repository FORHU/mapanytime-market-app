import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/auth/data/models/user_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> register(
    String email,
    String password, {
    required String firstName,
    required String lastName,
    String? middleName,
    String? countryCode,
    String roleName,
  });
  Future<UserModel> checkAuth(String token);

  /// Revokes the session server-side. Sends the refresh token so the API can
  /// delete the matching session row.
  Future<void> logout(String? refreshToken);

  /// Requests a one-time reset code be sent to [email].
  Future<void> requestPasswordReset(String email);

  /// Verifies [code] and sets [newPassword] for [email].
  Future<void> resetPassword(String email, String code, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<UserModel> login(String email, String password) async {
    final data = await _api.post(ApiEndpoints.login, {
      'email': email,
      'password': password,
      'roleName': 'BUYER',
    });
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<void> register(
    String email,
    String password, {
    required String firstName,
    required String lastName,
    String? middleName,
    String? countryCode,
    String roleName = 'BUYER',
  }) async {
    await _api.post(ApiEndpoints.register, {
      'email': email,
      'password': password,
      'roleName': roleName,
      'firstName': firstName,
      'lastName': lastName,
      if (middleName != null && middleName.isNotEmpty) 'middleName': middleName,
      if (countryCode != null && countryCode.isNotEmpty)
        'countryCode': countryCode,
    });
  }

  @override
  Future<UserModel> checkAuth(String token) async {
    final data = await _api.get(ApiEndpoints.me);
    final json = (data as Map).cast<String, dynamic>();
    // Inject token because the `UserModel.fromJson` requires it and the `me`
    // endpoint doesn't return it
    if (json.containsKey('data')) {
      (json['data'] as Map<String, dynamic>)['accessToken'] = token;
    } else {
      json['accessToken'] = token;
    }
    return UserModel.fromJson(json);
  }

  @override
  Future<void> logout(String? refreshToken) async {
    await _api.post(ApiEndpoints.logout, {
      if (refreshToken != null && refreshToken.isNotEmpty)
        'refreshToken': refreshToken,
    });
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _api.post(ApiEndpoints.forgotPassword, {'email': email});
  }

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    await _api.post(ApiEndpoints.resetPassword, {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }
}
