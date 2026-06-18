import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two-tier local storage:
/// * [SharedPreferences] for non-sensitive values (flags, prefs, cache keys).
/// * [FlutterSecureStorage] for secrets (auth tokens) — encrypted at rest.
class StorageService {
  StorageService(this._prefs, {FlutterSecureStorage? secure})
    : _secure = secure ?? const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  // --- Plain key/value ---
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);

  // --- Secure (access token) ---
  Future<void> saveToken(String token) =>
      _secure.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _secure.read(key: _tokenKey);

  // --- Secure (refresh token) ---
  Future<void> saveRefreshToken(String token) =>
      _secure.write(key: _refreshTokenKey, value: token);
  Future<String?> readRefreshToken() => _secure.read(key: _refreshTokenKey);

  /// Clears the whole authenticated session (access + refresh tokens).
  Future<void> clearSession() async {
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _refreshTokenKey);
  }
}

/// Overridden in `main()` with the resolved instance — see [ProviderScope].
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(sharedPreferencesProvider)),
);
