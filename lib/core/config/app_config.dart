import 'environment.dart';

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

  final Environment environment;
  final String appName;
  final String baseUrl;
  final bool enableLogging;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;

  factory AppConfig.dev() => const AppConfig(
        environment: Environment.dev,
        appName: 'Clean Flutter App (Dev)',
        baseUrl: 'https://dev.api.example.com',
        enableLogging: true,
      );

  factory AppConfig.prod() => const AppConfig(
        environment: Environment.prod,
        appName: 'Clean Flutter App',
        baseUrl: 'https://api.example.com',
        enableLogging: false,
      );
}
