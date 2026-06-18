import 'package:flutter_template/core/config/environment.dart';

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
        defaultValue: 'flutter_template',
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
    );
  }

  /// Explicit development config used by `main_dev.dart` — works without any
  /// `--dart-define`, with logging on.
  const AppConfig.dev()
    : environment = Environment.dev,
      appName = 'Clean Flutter App (Dev)',
      baseUrl = 'https://dev.api.example.com',
      enableLogging = true;

  /// Explicit production config used by `main_prod.dart` — logging off.
  const AppConfig.prod()
    : environment = Environment.prod,
      appName = 'Clean Flutter App',
      baseUrl = 'https://api.example.com',
      enableLogging = false;

  final Environment environment;
  final String appName;
  final String baseUrl;
  final bool enableLogging;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
