import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Development entry point: `flutter run -t lib/main_dev.dart`
Future<void> main() => bootstrap(AppConfig.fromEnvironment());
