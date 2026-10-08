import 'package:dio/dio.dart';
import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/auth/data/models/user_model.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> loginWithFacebook(String accessToken);
  Future<UserModel> loginWithGoogle(String idToken);

  /// With a [profile] (buyer sign-up with a valid ID) the request is
  /// multipart and carries the ID photo as `validId`.
  Future<void> register(
    String email,
    String password, {
    required String firstName,
    required String lastName,
    String? middleName,
    String? countryCode,
    String roleName,
    RegistrationProfile? profile,
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
  Future<UserModel> loginWithFacebook(String accessToken) async {
    final data = await _api.post(ApiEndpoints.facebookLogin, {
      'accessToken': accessToken,
    });
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<UserModel> loginWithGoogle(String idToken) async {
    final data = await _api.post(ApiEndpoints.googleLogin, {
      'idToken': idToken,
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
    RegistrationProfile? profile,
  }) async {
    final fields = <String, Object>{
      'email': email,
      'password': password,
      'roleName': roleName,
      'firstName': firstName,
      'lastName': lastName,
      if (middleName != null && middleName.isNotEmpty) 'middleName': middleName,
      if (countryCode != null && countryCode.isNotEmpty)
        'countryCode': countryCode,
    };
    if (profile == null) {
      await _api.post(ApiEndpoints.register, fields);
      return;
    }

    final dob = profile.dateOfBirth;
    await _api.post(
      ApiEndpoints.register,
      FormData.fromMap({
        ...fields,
        'dateOfBirth':
            '${dob.year.toString().padLeft(4, '0')}-'
            '${dob.month.toString().padLeft(2, '0')}-'
            '${dob.day.toString().padLeft(2, '0')}',
        if (profile.sex != null) 'sex': profile.sex!.apiValue,
        'phoneNumber': profile.phoneNumber,
        'address': profile.address,
        'validIdType': profile.idType.apiValue,
        'validIdNumber': profile.idNumber,
        'validId': await MultipartFile.fromFile(
          profile.idPhotoPath,
          filename: 'valid-id.${_extension(profile.idPhotoPath)}',
          contentType: DioMediaType(
            'image',
            _imageSubtype(profile.idPhotoPath),
          ),
        ),
      }),
    );
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? 'jpg' : path.substring(dot + 1).toLowerCase();
  }

  /// MIME subtype the API accepts for the photo; image_picker re-encodes
  /// camera shots and resized picks as JPEG.
  static String _imageSubtype(String path) => switch (_extension(path)) {
    'png' => 'png',
    'webp' => 'webp',
    _ => 'jpeg',
  };

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
