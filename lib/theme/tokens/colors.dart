import 'package:flutter/material.dart';

/// Design tokens — colors. Light canvas, single accent (see DESIGN.md).
class AppColors {
  AppColors._();

  static const ui = _UI();
  static const text = _Text();
  static const status = _Status();

  /// The app's single accent — still named `ink` for its historical role as
  /// a near-black fill, now the brand blue. Primary buttons, icon buttons,
  /// selected chips/rows, the active nav pill.
  static const Color ink = Color(0xFF1B2CC1);

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

  /// Image placeholder inside a white product card. #F1F2F8.
  Color get surfaceMutedCool => const Color(0xFFF1F2F8);

  /// Outline of a white product card on the page background. #DCDFEA.
  Color get borderCard => const Color(0xFFDCDFEA);

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

  /// Text on a [warning]-tinted chip (e.g. the rating chip) — the warning
  /// hue darkened enough to read at 12px. #7A5200.
  Color get warningStrong => const Color(0xFF7A5200);

  /// Text on an [error]-tinted chip — the error hue darkened enough to read
  /// at 11px. #B4282D.
  Color get errorStrong => const Color(0xFFB4282D);
}
