import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';

UserEntity _userWithRoles(List<String> roles) =>
    UserEntity(id: 'u1', email: 'u@example.com', roles: roles);

void main() {
  group('UserEntity.hasPlatformAdminRole', () {
    test('is false when roles are empty, so an unknown user is restricted', () {
      expect(_userWithRoles(const []).hasPlatformAdminRole, false);
    });

    test('is false for a plain buyer', () {
      expect(_userWithRoles(const ['BUYER']).hasPlatformAdminRole, false);
    });

    test('is false for a seller, who is not a platform admin', () {
      expect(_userWithRoles(const ['SELLER']).hasPlatformAdminRole, false);
    });

    test('is true when an admin role sits alongside others', () {
      expect(
        _userWithRoles(const ['BUYER', 'ADMIN']).hasPlatformAdminRole,
        true,
      );
    });

    test('is true for DEVELOPER', () {
      expect(_userWithRoles(const ['DEVELOPER']).hasPlatformAdminRole, true);
    });

    test('is true for SUPER_ADMIN', () {
      expect(_userWithRoles(const ['SUPER_ADMIN']).hasPlatformAdminRole, true);
    });

    test('is false for an unrecognised role name', () {
      expect(
        _userWithRoles(const ['SUPPORT_AGENT']).hasPlatformAdminRole,
        false,
      );
    });

    test('is case sensitive, matching the backend spelling exactly', () {
      expect(_userWithRoles(const ['admin']).hasPlatformAdminRole, false);
    });

    test('defaults to no roles when the field is omitted', () {
      expect(
        const UserEntity(id: 'u1', email: 'u@example.com').roles,
        isEmpty,
      );
    });
  });
}
