import 'package:mapanytime_market_app/bootstrap.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';

/// Default entry point for a bare `flutter run` (no `-t`) and for release
/// builds that inject config via `--dart-define-from-file`. Reads the active
/// environment from `--dart-define` values, defaulting to dev.
///
/// For explicit, define-free targets use `lib/main_dev.dart` or
/// `lib/main_prod.dart`.
Future<void> main() => bootstrap(AppConfig.fromEnvironment());
