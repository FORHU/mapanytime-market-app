/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // Users
  static const String users = '/users';
  static const String me = '/users/me';

  /// Stores near a `lat`/`lng` query origin (used by the world map).
  static const String storesNearby = '/stores/nearby';

  /// Global categories. With no `parentId` query it returns the root (parent)
  /// categories — used for the map filter chips.
  static const String categories = '/categories';
}
