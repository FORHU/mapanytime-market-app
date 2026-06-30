import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/app.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mapanytime_market_app/core/utils/logger.dart';
import 'package:mapanytime_market_app/core/utils/platform_support.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared startup used by every entry point. Pins the chosen [config], does
/// async init (SharedPreferences), then runs the app. Keep environment-
/// specific logic in the entry points, not here.
Future<void> bootstrap(AppConfig config) async {
  AppConfig.instance = config;

  WidgetsFlutterBinding.ensureInitialized();
  // mapbox_maps_flutter is mobile-only (Android/iOS). On web this plugin call
  // throws (MissingPluginException) before runApp(), causing a blank white
  // screen. Skip it so non-map features can still be developed/tested on web.
  if (isMapboxSupported) {
    MapboxOptions.setAccessToken(config.mapboxPublicToken);
  }

  final prefs = await SharedPreferences.getInstance();

  if (config.enableLogging) {
    appLogger.i(
      'Starting ${config.appName} '
      '[${config.environment.name}] -> ${config.baseUrl}',
    );
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}
