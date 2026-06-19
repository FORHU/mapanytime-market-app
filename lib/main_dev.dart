import 'package:mapanytime_market_web/bootstrap.dart';
import 'package:mapanytime_market_web/core/config/app_config.dart';

/// Development entry point: `flutter run -t lib/main_dev.dart`.
/// Pins the explicit dev config (logging on) — no `--dart-define` required.
Future<void> main() => bootstrap(const AppConfig.dev());
