import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

class AppCardTheme {
  AppCardTheme._();

  static CardThemeData get cardTheme => CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    // Depth in this system comes from AppEffects' explicit BoxShadow tokens,
    // not Material elevation — kept minimal here since Material's own Card
    // widget is a fallback, not the app's primary card (see GlassCard).
    elevation: 1,
    clipBehavior: Clip.antiAlias,
  );
}
