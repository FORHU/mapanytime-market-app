import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/dark_theme.dart';
import 'package:mapanytime_market_app/theme/light_theme.dart';

/// The central Theme configuration for the application.
class AppTheme {
  AppTheme._();

  static ThemeData get light => LightTheme.build();
  static ThemeData get dark => DarkTheme.build();
}
