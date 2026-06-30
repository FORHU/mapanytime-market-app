import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapanytime_market_app/core/config/environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.baseUrl,
    required this.mapboxPublicToken,
    this.enableLogging = false,
  });

  /// Builds config from `flutter_dotenv` values loaded at runtime.
  /// Used by the default entry point (`main.dart`).
  factory AppConfig.fromEnvironment() {
    final envString = dotenv.env['ENVIRONMENT'] ?? 'dev';
    return AppConfig(
      environment: envString == 'prod' ? Environment.prod : Environment.dev,
      appName: dotenv.env['APP_NAME'] ?? 'mapanytime_market_app',
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      mapboxPublicToken:
          dotenv.env['MAPBOX_PUBLIC_TOKEN'] ??
          'pk.eyJ1IjoianVuZ2t3YW5zaGluIiwiYSI6ImNtcW9xcGE2aDA1d2wycXF2cXFzdG14'
              'bWcifQ.HR1a5C0MxCY4M0f1yEt6-A',
      enableLogging:
          (dotenv.env['ENABLE_LOGGING'] ??
                  (envString != 'prod' ? 'true' : 'false'))
              .toLowerCase() ==
          'true',
    );
  }

  /// Explicit development config used by `main_dev.dart` — works without any
  /// `--dart-define`, with logging on and pointed at the real backend.
  const AppConfig.dev()
    : environment = Environment.dev,
      appName = 'MapAnytime Market (Dev)',
      baseUrl = '',
      mapboxPublicToken = '',
      enableLogging = true;

  /// Explicit production config used by `main_prod.dart` — logging off, real
  /// backend.
  const AppConfig.prod()
    : environment = Environment.prod,
      appName = 'MapAnytime Market',
      baseUrl = '',
      mapboxPublicToken = '',
      enableLogging = false;

  final Environment environment;
  final String appName;
  final String baseUrl;
  final String mapboxPublicToken;
  final bool enableLogging;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
