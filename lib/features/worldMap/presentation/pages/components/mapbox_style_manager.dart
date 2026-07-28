import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Renders store markers using custom high-definition canvas bitmap ribbons.
/// Displays a red store pin dot with a floating store ribbon badge above it.
class MapboxStyleManager {
  MapboxStyleManager(this.mapboxMap, {this.onStoreTap});

  final MapboxMap mapboxMap;

  /// Called with a store id when its marker or ribbon is tapped.
  final void Function(String storeId)? onStoreTap;

  PointAnnotationManager? _pointManager;

  // annotation id -> store id, to resolve taps back to a store.
  final Map<String, String> _annotationToStore = {};

  // Cached so selection highlighting can re-render without a new fetch.
  List<StoreEntity> _stores = [];
  String? _selectedStoreId;

  /// Creates annotation managers (once) and registers tap handling.
  Future<void> initializeStoreLayers() async {
    if (_pointManager == null) {
      _pointManager =
          await mapboxMap.annotations.createPointAnnotationManager();
      _pointManager!.tapEvents(
        onTap: (annotation) {
          final storeId = _annotationToStore[annotation.id];
          if (storeId != null) onStoreTap?.call(storeId);
        },
      );
    }

    await _render();
  }

  /// Replaces all markers & store name ribbons with one per store.
  Future<void> updateGeoJsonSource(List<StoreEntity> stores) async {
    _stores = stores;
    await _render();
  }

  /// Highlights the selected store (and de-highlights the rest).
  Future<void> updateSelectedStore(String? selectedStoreId) async {
    _selectedStoreId = selectedStoreId;
    await _render();
  }

  /// Generates a high-definition PNG canvas bitmap containing the store ribbon
  /// and red pin dot.
  static Future<Uint8List> _createStoreRibbonImage(
    String storeName,
    bool isSelected,
  ) async {
    final recorder = ui.PictureRecorder();
    const canvasWidth = 240.0;
    const canvasHeight = 76.0;

    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
    );

    final ribbonBgPaint = Paint()
      ..color = isSelected ? const Color(0xFF007AFF) : const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final ribbonBorderPaint = Paint()
      ..color = isSelected ? Colors.white : const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pinDotPaint = Paint()
      ..color = isSelected ? const Color(0xFF007AFF) : const Color(0xFFFF3B30)
      ..style = PaintingStyle.fill;

    final pinDotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final ribbonRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 4, 232, 38),
      const Radius.circular(12),
    );

    // 1. Draw Ribbon Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas
      ..drawRRect(ribbonRRect.shift(const Offset(0, 2)), shadowPaint)

      // 2. Draw Ribbon Pill Body & Border
      ..drawRRect(ribbonRRect, ribbonBgPaint)
      ..drawRRect(ribbonRRect, ribbonBorderPaint);

    // 3. Draw Store Name Text
    final tp = TextPainter(
      text: TextSpan(
        text: '🏪  $storeName',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    tp
      ..layout(maxWidth: 216)
      ..paint(canvas, Offset(12, (38 - tp.height) / 2 + 4));

    // 4. Draw Pointer Triangle connecting Ribbon to Pin Dot
    final pointerPath = Path()
      ..moveTo(112, 42)
      ..lineTo(120, 56)
      ..lineTo(128, 42)
      ..close();

    canvas
      ..drawPath(pointerPath, ribbonBgPaint)
      ..drawPath(pointerPath, ribbonBorderPaint);

    // 5. Draw Red Pin Circle Dot at Bottom Center
    const pinCenter = Offset(120, 62);
    canvas
      ..drawCircle(pinCenter, 10, pinDotPaint)
      ..drawCircle(pinCenter, 10, pinDotBorderPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _render() async {
    final pointManager = _pointManager;
    if (pointManager == null) return;

    try {
      await pointManager.deleteAll();
      _annotationToStore.clear();

      if (_stores.isEmpty) return;

      final pointOptions = <PointAnnotationOptions>[];

      for (final s in _stores) {
        final selected = s.id == _selectedStoreId;
        final imageBytes = await _createStoreRibbonImage(s.name, selected);

        pointOptions.add(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(s.lng, s.lat)),
            image: imageBytes,
            iconAnchor: IconAnchor.BOTTOM,
          ),
        );
      }

      final createdPoints = await pointManager.createMulti(pointOptions);
      for (var i = 0; i < createdPoints.length && i < _stores.length; i++) {
        final ann = createdPoints[i];
        if (ann != null) _annotationToStore[ann.id] = _stores[i].id;
      }
    } on Exception catch (e, stack) {
      debugPrint('Failed to render store ribbon badges: $e\n$stack');
    }
  }

  Future<void> hidePoiLayers() async {
    try {
      final layers = await mapboxMap.style.getStyleLayers();
      for (final layer in layers) {
        if (layer == null) continue;
        final id = layer.id.toLowerCase();
        // Hide points of interest and transit labels
        if (id.contains('poi') || id.contains('transit')) {
          await mapboxMap.style.setStyleLayerProperty(
            layer.id,
            'visibility',
            'none',
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('Note: Some POI layers could not be hidden: $e');
    }
  }
}
