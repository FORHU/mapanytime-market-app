import 'package:mapanytime_market_web/core/config/environment.dart';

/// Per-environment settings, fixed at startup.
///
/// One [AppConfig] is chosen by the entry point (main_dev/main_prod) and
/// assigned to [instance] inside `bootstrap()`. Read it anywhere via
/// `AppConfig.instance`.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.baseUrl,
    this.enableLogging = false,
    this.useMock = false,
  });

  /// Builds config from `--dart-define`/`--dart-define-from-file` values.
  /// Used by the default entry point (`main.dart`) and release builds.
  factory AppConfig.fromEnvironment() {
    const envString = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'dev',
    );
    return const AppConfig(
      environment: envString == 'prod' ? Environment.prod : Environment.dev,
      appName: String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'mapanytime_market_web',
      ),
      baseUrl: String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'https://api.example.com',
      ),
      // Defaults on in dev, off in prod when the flag is absent.
      enableLogging: bool.fromEnvironment(
        'ENABLE_LOGGING',
        defaultValue: envString != 'prod',
      ),
      // Serve canned responses (no server needed) unless explicitly disabled.
      useMock: bool.fromEnvironment(
        'USE_MOCK',
        defaultValue: envString != 'prod',
      ),
    );
  }

  /// Explicit development config used by `main_dev.dart` — works without any
  /// `--dart-define`, with logging on and the mock backend enabled.
  const AppConfig.dev()
    : environment = Environment.dev,
      appName = 'Clean Flutter App (Dev)',
      baseUrl = 'https://reqres.in/api',
      enableLogging = true,
      useMock = true;

  /// Explicit production config used by `main_prod.dart` — logging off, real
  /// backend.
  const AppConfig.prod()
    : environment = Environment.prod,
      appName = 'Clean Flutter App',
      baseUrl = 'https://api.example.com',
      enableLogging = false,
      useMock = false;

  final Environment environment;
  final String appName;
  final String baseUrl;
  final bool enableLogging;

  /// When true, a `MockInterceptor` serves canned responses so the app runs
  /// with no backend. Keep off in production.
  final bool useMock;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
