import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/data/models/user_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
// ignore: one_member_abstracts
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<UserModel> login(String email, String password) async {
    final json = await _api.post('/login', {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(json);
  }
}
