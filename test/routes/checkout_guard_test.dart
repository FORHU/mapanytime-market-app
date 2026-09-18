import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';
import 'package:mapanytime_market_app/routes/app_routes.dart';

UserEntity _userWithRoles(List<String> roles) =>
    UserEntity(id: 'u1', email: 'u@example.com', roles: roles);

void main() {
  group('isCheckoutRestricted while checkout is disabled', () {
    test('blocks a plain buyer', () {
      expect(
        isCheckoutRestricted(
          buyerCheckoutEnabled: false,
          user: _userWithRoles(const ['BUYER']),
        ),
        true,
      );
    });

    test('blocks a null user, failing closed', () {
      expect(
        isCheckoutRestricted(buyerCheckoutEnabled: false, user: null),
        true,
      );
    });

    test('blocks a user whose roles are unknown', () {
      expect(
        isCheckoutRestricted(
          buyerCheckoutEnabled: false,
          user: _userWithRoles(const []),
        ),
        true,
      );
    });

    test('allows ADMIN', () {
      expect(
        isCheckoutRestricted(
          buyerCheckoutEnabled: false,
          user: _userWithRoles(const ['ADMIN']),
        ),
        false,
      );
    });

    test('allows DEVELOPER', () {
      expect(
        isCheckoutRestricted(
          buyerCheckoutEnabled: false,
          user: _userWithRoles(const ['DEVELOPER']),
        ),
        false,
      );
    });

    test('allows SUPER_ADMIN', () {
      expect(
        isCheckoutRestricted(
          buyerCheckoutEnabled: false,
          user: _userWithRoles(const ['SUPER_ADMIN']),
        ),
        false,
      );
    });
  });

  group('isCheckoutRestricted once checkout is re-enabled', () {
    test('allows a plain buyer', () {
      expect(
        isCheckoutRestricted(
          buyerCheckoutEnabled: true,
          user: _userWithRoles(const ['BUYER']),
        ),
        false,
      );
    });

    test('allows a null user', () {
      expect(
        isCheckoutRestricted(buyerCheckoutEnabled: true, user: null),
        false,
      );
    });
  });
}
