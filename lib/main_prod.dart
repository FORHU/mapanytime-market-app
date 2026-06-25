import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapanytime_market_app/bootstrap.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';

/// Production entry point: `flutter run -t lib/main_prod.dart`.
/// Loads variables from `.env.prod`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.prod');
  await bootstrap(AppConfig.fromEnvironment());
}
