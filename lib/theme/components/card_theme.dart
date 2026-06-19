import 'package:flutter/material.dart';
import '../tokens/radius.dart';

class AppCardTheme {
  AppCardTheme._();

  static CardThemeData get cardTheme => CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
      );
}
