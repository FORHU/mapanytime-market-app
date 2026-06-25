import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/auth/data/models/user_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, {String? name});
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
  Future<UserModel> register(
    String email,
    String password, {
    String? name,
  }) async {
    final data = await _api.post(ApiEndpoints.register, {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }
}
