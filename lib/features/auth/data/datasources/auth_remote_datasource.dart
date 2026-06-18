import '../../../../core/services/api_service.dart';
import '../models/user_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
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
