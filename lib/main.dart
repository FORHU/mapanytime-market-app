import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Default entry point for a bare `flutter run` (no `-t`). Uses the dev
/// environment. For explicit targets, run `lib/main_dev.dart` or
/// `lib/main_prod.dart`.
Future<void> main() => bootstrap(AppConfig.fromEnvironment());
