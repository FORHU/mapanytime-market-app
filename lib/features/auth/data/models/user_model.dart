import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';

/// Data-layer extension of [UserEntity] that knows how to (de)serialize and
/// carries the auth token returned by the API.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
    token: json['token'] as String,
  );

  final String token;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'token': token,
  };

  @override
  List<Object?> get props => [...super.props, token];
}
