import 'package:mapanytime_market_app/core/config/environment.dart';

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
    required this.mapboxPublicToken,
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
        defaultValue: 'mapanytime_market_app',
      ),
      baseUrl: String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'http://172.30.32.1:3002/api/v1',
      ),
      mapboxPublicToken: String.fromEnvironment('MAPBOX_PUBLIC_TOKEN'),
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
      appName = 'MapAnytime Market (Dev)',
      baseUrl = 'http://172.30.32.1:3002/api/v1',
      // Public Mapbox token (pk...) — safe to embed for dev. Restrict it by
      // URL/scope in the Mapbox dashboard. Keep secret (sk...) tokens out of
      // source; those belong in ~/.gradle/gradle.properties for the build.
      mapboxPublicToken =
          'pk.eyJ1IjoianVuZ2t3YW5zaGluIiwiYSI6ImNtcW9xcGE2aDA1d2wy'
          'cXF2cXFzdG14bWcifQ.HR1a5C0MxCY4M0f1yEt6-A',
      enableLogging = true,
      // Backend APIs aren't built yet — serve canned responses from
      // MockInterceptor. Flip to false once the real endpoints exist.
      useMock = true;

  /// Explicit production config used by `main_prod.dart` — logging off, real
  /// backend.
  const AppConfig.prod()
    : environment = Environment.prod,
      appName = 'MapAnytime Market',
      baseUrl = 'http://172.30.32.1:3002/api/v1',
      mapboxPublicToken = '',
      enableLogging = false,
      useMock = false;

  final Environment environment;
  final String appName;
  final String baseUrl;
  final String mapboxPublicToken;
  final bool enableLogging;

  /// When true, a `MockInterceptor` serves canned responses so the app runs
  /// with no backend. Keep off in production.
  final bool useMock;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
