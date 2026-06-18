import 'package:flutter/material.dart';

import 'package:flutter_template/core/constants/app_colors.dart';

/// Dark theme for the app.
class DarkTheme {
  DarkTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
