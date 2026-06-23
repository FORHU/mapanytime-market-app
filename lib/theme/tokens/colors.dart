import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const brand = _Brand();
  static const ui = _UI();
  static const text = _Text();
  static const status = _Status();
}

class _Brand {
  const _Brand();
  Color get primary => const Color(0xFF6750A4);
  Color get secondary => const Color(0xFF625B71);
}

class _UI {
  const _UI();

  // Light Mode UI
  Color get background => const Color(0xFFFEF7FF);
  Color get surface => const Color(0xFFFFFBFE);

  // Dark Mode UI
  Color get backgroundDark => const Color(0xFF141218);
  Color get surfaceDark => const Color(0xFF1D1B20);
}

class _Text {
  const _Text();

  // Light Mode Text
  Color get primary => const Color(0xFF1C1B1F);
  Color get secondary => const Color(0xFF49454F);

  // Dark Mode Text
  Color get primaryDark => const Color(0xFFE6E1E5);
  Color get secondaryDark => const Color(0xFFCAC4D0);
}

class _Status {
  const _Status();
  Color get error => const Color(0xFFB3261E);
  Color get success => const Color(0xFF4CAF50);
}
