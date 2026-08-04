import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapanytime_market_app/bootstrap.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';

/// Default entry point for a bare `flutter run` (no `-t`) and for release
/// builds that inject config via `--dart-define-from-file`. Reads the active
/// environment from `--dart-define` values, defaulting to dev.
///
/// For explicit, define-free targets use `lib/main_dev.dart` or
/// `lib/main_prod.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Which env asset to load, e.g. `--dart-define=ENV_FILE=.env.prod`. Defaults
  // to dev so a bare `flutter run` behaves as before; without this a release
  // build through this entry point would silently ship dev config.
  const envFile = String.fromEnvironment('ENV_FILE', defaultValue: '.env.dev');
  await dotenv.load(fileName: envFile);
  await bootstrap(AppConfig.fromEnvironment());
}
