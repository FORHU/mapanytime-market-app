import 'package:flutter/material.dart';

/// Design tokens — colors. Light canvas, single ink accent (see DESIGN.md).
class AppColors {
  AppColors._();

  static const ui = _UI();
  static const text = _Text();
  static const status = _Status();

  /// The app's single accent — near-black ink. Primary buttons, icon
  /// buttons, selected chips/rows, the active nav pill.
  static const Color ink = Color(0xFF0D0D0F);

  /// Tap-down state for ink surfaces only.
  static const Color inkPressed = Color(0xFF000000);
}

class _UI {
  const _UI();

  /// Scaffold background — #F7F7F8.
  Color get background => const Color(0xFFF7F7F8);

  /// Card/panel fill — #FFFFFF.
  Color get surface => const Color(0xFFFFFFFF);

  /// Unselected chip/row fill, search bar fill, quantity-stepper fill —
  /// anything "on the canvas but grouped." #F5F5F6.
  Color get surfaceMuted => const Color(0xFFF5F5F6);

  /// Reserved for the rare white-on-white legibility case. Not a default
  /// outline — fill contrast and shadow do the depth work in this system.
  /// #ECEDF0.
  Color get borderHairline => const Color(0xFFECEDF0);
}

class _Text {
  const _Text();

  /// Titles, body, primary labels. #14161C.
  Color get primary => const Color(0xFF14161C);

  /// Supporting text — ratings, unselected row labels, card subtitles.
  /// #6B7280.
  Color get secondary => const Color(0xFF6B7280);

  /// Least-emphasis text — hint text, muted icons. #9AA0AE.
  Color get tertiary => const Color(0xFF9AA0AE);

  /// The only text color allowed on an ink-filled surface. #FFFFFF.
  Color get onInk => const Color(0xFFFFFFFF);
}

class _Status {
  const _Status();

  // Reserved for order/store state — never decorative.
  Color get error => const Color(0xFFE5484D);
  Color get success => const Color(0xFF2FA36B);
  Color get warning => const Color(0xFFD89614);
}
