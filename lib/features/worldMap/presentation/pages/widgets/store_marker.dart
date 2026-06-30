import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

class StoreMarkerUtils {
  /// Generates a brand-colored rounded rectangle image dynamically using
  /// Flutter Canvas to be used natively by Mapbox as a marker background.
  static Future<Uint8List> getCustomMarkerBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 64.0;
    const height = 64.0;
    final paint = Paint()
      ..color = AppColors.brand.primary
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData();

    return byteData!.buffer.asUint8List();
  }
}
