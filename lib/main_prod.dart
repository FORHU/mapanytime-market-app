import 'package:flutter_template/bootstrap.dart';
import 'package:flutter_template/core/config/app_config.dart';

/// Production entry point: `flutter run -t lib/main_prod.dart`
Future<void> main() => bootstrap(AppConfig.fromEnvironment());
