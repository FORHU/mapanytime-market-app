import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/auth/data/models/user_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> register(
    String email,
    String password, {
    String? name,
    String? countryCode,
  });
  Future<UserModel> checkAuth(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<UserModel> login(String email, String password) async {
    final data = await _api.post(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<void> register(
    String email,
    String password, {
    String? name,
    String? countryCode,
  }) async {
    await _api.post(ApiEndpoints.register, {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
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
}
