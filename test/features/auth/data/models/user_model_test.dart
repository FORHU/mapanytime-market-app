import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel.fromJson roles', () {
    test('parses the login shape, where roles are plain strings', () {
      final user = UserModel.fromJson(const {
        'data': {
          'accessToken': 'tok',
          'user': {
            'id': 'u1',
            'email': 'u@example.com',
            'roles': ['BUYER', 'ADMIN'],
          },
        },
      });

      expect(user.roles, ['BUYER', 'ADMIN']);
      expect(user.hasPlatformAdminRole, true);
    });

    test('parses the /users/me shape, where roles are objects', () {
      final user = UserModel.fromJson(const {
        'data': {
          'accessToken': 'tok',
          'id': 'u1',
          'email': 'u@example.com',
          'roles': [
            {'id': 'r1', 'roleName': 'BUYER'},
            {'id': 'r2', 'roleName': 'DEVELOPER'},
          ],
        },
      });

      expect(user.roles, ['BUYER', 'DEVELOPER']);
      expect(user.hasPlatformAdminRole, true);
    });

    test('defaults to empty for a user cached before roles existed', () {
      final user = UserModel.fromJson(const {
        'id': 'u1',
        'email': 'u@example.com',
        'token': 'tok',
      });

      expect(user.roles, isEmpty);
      expect(user.hasPlatformAdminRole, false);
    });

    // A cast here would throw a TypeError, which StorageService.readUserModel
    // does not catch — it would escape AuthController.build() and break
    // start-up.
    test('returns empty rather than throwing when roles is not a list', () {
      final user = UserModel.fromJson(const {
        'id': 'u1',
        'email': 'u@example.com',
        'token': 'tok',
        'roles': 'ADMIN',
      });

      expect(user.roles, isEmpty);
    });

    test('skips entries that are neither a string nor a roleName map', () {
      final user = UserModel.fromJson(const {
        'id': 'u1',
        'email': 'u@example.com',
        'token': 'tok',
        'roles': [
          'BUYER',
          42,
          null,
          {'noRoleName': 'ADMIN'},
          {'roleName': 'SUPER_ADMIN'},
        ],
      });

      expect(user.roles, ['BUYER', 'SUPER_ADMIN']);
    });
  });

  test('toJson serializes roles', () {
    const user = UserModel(
      id: 'u1',
      email: 'u@example.com',
      token: 'tok',
      roles: ['BUYER', 'ADMIN'],
    );

    expect(user.toJson()['roles'], ['BUYER', 'ADMIN']);
  });

  test('roles survive a toJson/fromJson round trip through the cache', () {
    const original = UserModel(
      id: 'u1',
      email: 'u@example.com',
      token: 'tok',
      roles: ['BUYER', 'SUPER_ADMIN'],
    );

    final restored = UserModel.fromJson(original.toJson());

    expect(restored.roles, ['BUYER', 'SUPER_ADMIN']);
    expect(restored.hasPlatformAdminRole, true);
  });
}
