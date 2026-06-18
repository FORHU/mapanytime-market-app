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

  factory AppConfig.fromEnvironment() {
    const envString = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'dev',
    );
    return const AppConfig(
      environment: envString == 'prod' ? Environment.prod : Environment.dev,
      appName: String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'flutter_tremplate',
      ),
      baseUrl: String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'https://api.example.com',
      ),
    );
  }

  final Environment environment;
  final String appName;
  final String baseUrl;
  final bool enableLogging;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
