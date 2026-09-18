import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapanytime_market_app/core/config/environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.baseUrl,
    required this.mapboxPublicToken,
    this.enableLogging = false,
    this.buyerCheckoutEnabled = false,
    this.googleServerClientId = '',
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
          dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? defaultMapboxPublicToken,
      enableLogging:
          (dotenv.env['ENABLE_LOGGING'] ??
                  (envString != 'prod' ? 'true' : 'false'))
              .toLowerCase() ==
          'true',
      // Unset means blocked — alpha testing is the default state, so no
      // .env file needs to carry this until checkout is re-enabled.
      buyerCheckoutEnabled:
          (dotenv.env['BUYER_CHECKOUT_ENABLED'] ?? 'false').toLowerCase() ==
          'true',
      googleServerClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '',
    );
  }

  /// Explicit development config used by `main_dev.dart` — works without any
  /// `--dart-define`, with logging on and pointed at the real backend.
  const AppConfig.dev()
    : environment = Environment.dev,
      appName = 'MapAnytime Market (Dev)',
      baseUrl = 'http://localhost:4002/api/v1',
      mapboxPublicToken = defaultMapboxPublicToken,
      enableLogging = true,
      buyerCheckoutEnabled = false,
      googleServerClientId = '';

  /// Explicit production config used by `main_prod.dart` — logging off, real
  /// backend.
  const AppConfig.prod()
    : environment = Environment.prod,
      appName = 'MapAnytime Market',
      baseUrl = '',
      mapboxPublicToken = defaultMapboxPublicToken,
      enableLogging = false,
      buyerCheckoutEnabled = false,
      googleServerClientId = '';

  final Environment environment;
  final String appName;
  final String baseUrl;
  final String mapboxPublicToken;
  final bool enableLogging;

  /// Alpha testing: when false, regular buyers are blocked from checkout.
  /// Set true to re-enable.
  ///
  /// Platform admins (`ADMIN`, `DEVELOPER`, `SUPER_ADMIN`) are unaffected
  /// either way — see `isCheckoutRestricted` in `lib/routes/app_routes.dart`.
  final bool buyerCheckoutEnabled;

  /// The *Web application* OAuth client ID from Google Cloud Console — the
  /// same one as the API's `GOOGLE_CLIENT_ID` and the web app's
  /// `NEXT_PUBLIC_GOOGLE_CLIENT_ID`. Passed to `GoogleSignIn.initialize` as
  /// `serverClientId` so the ID token this app gets back carries that
  /// audience, which is what the API verifies it against — not a
  /// platform-specific Android/iOS client ID. Empty disables the button.
  final String googleServerClientId;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Origin for the realtime socket — the server host without the REST path
  /// (e.g. `http://192.168.1.20:3002` from `.../api/v1`). Socket.IO mounts at
  /// the root, so the `/api/v1` suffix must be stripped.
  String get socketUrl {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return baseUrl;
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  /// Public Mapbox token used when `MAPBOX_PUBLIC_TOKEN` isn't supplied.
  ///
  /// `pk.*` tokens are meant to be public, and this one ships inside the app
  /// bundle regardless (`.env.dev`/`.env.prod` are pubspec assets), so holding
  /// it here adds no exposure. Restrict it by app/URL in the Mapbox account so
  /// the quota can't be spent by others.
  static const String defaultMapboxPublicToken =
      'pk.eyJ1IjoianVuZ2t3YW5zaGluIiwiYSI6ImNtcW9xcGE2aDA1d2wycXF2cXFzdG14'
      'bWcifQ.HR1a5C0MxCY4M0f1yEt6-A';

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
