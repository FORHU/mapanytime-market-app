import 'package:flutter/material.dart';

/// Design tokens — corner radii. Premium look uses generous 20–28 corners.
class AppRadius {
  AppRadius._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;

  /// Default card radius.
  static const card = 24.0;

  /// Largest radius (hero panels, sheets).
  static const xl = 28.0;

  /// Fully rounded (pills, chips, FABs).
  static const pill = 999.0;

  // Convenience BorderRadius getters.
  static BorderRadius get brSm => BorderRadius.circular(sm);
  static BorderRadius get brMd => BorderRadius.circular(md);
  static BorderRadius get brLg => BorderRadius.circular(lg);
  static BorderRadius get brCard => BorderRadius.circular(card);
  static BorderRadius get brXl => BorderRadius.circular(xl);
  static BorderRadius get brPill => BorderRadius.circular(pill);
}
