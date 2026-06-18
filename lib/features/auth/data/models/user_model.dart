import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';

/// Data-layer extension of [UserEntity] that knows how to (de)serialize and
/// carries the auth token returned by the API.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required this.token,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
    token: json['token'] as String,
    refreshToken: json['refreshToken'] as String?,
  );

  /// Short-lived access token (bearer).
  final String token;

  /// Long-lived token used to obtain a new access token. Optional — some
  /// backends issue only an access token.
  final String? refreshToken;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'token': token,
    'refreshToken': refreshToken,
  };

  @override
  List<Object?> get props => [...super.props, token, refreshToken];
}
