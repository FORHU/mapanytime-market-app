import 'package:flutter/material.dart';

import 'light_theme.dart';
import 'dark_theme.dart';

/// The central Theme configuration for the application.
class AppTheme {
  AppTheme._();

  static ThemeData get light => LightTheme.build();
  static ThemeData get dark => DarkTheme.build();
}
