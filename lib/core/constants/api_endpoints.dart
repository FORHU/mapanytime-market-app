/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/login';
  static const String refresh = '/refresh';
  static const String logout = '/logout';

  /// Sample protected resource used to demonstrate a GET with the bearer token.
  static const String users = '/users';
}
