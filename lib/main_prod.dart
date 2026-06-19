import 'package:mapanytime_market_app/bootstrap.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';

/// Production entry point: `flutter run -t lib/main_prod.dart`.
/// Pins the explicit prod config (logging off).
Future<void> main() => bootstrap(const AppConfig.prod());
