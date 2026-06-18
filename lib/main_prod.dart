import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Production entry point: `flutter run -t lib/main_prod.dart`
Future<void> main() => bootstrap(AppConfig.prod());
