import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Renders store markers the way dense point-of-interest maps do: a small
/// category-colored icon anchored exactly at the coordinate with the
/// merchant's name floating beside it, collapsing to a plain colored dot
/// (no clustering — every merchant keeps its own dot) once the camera is
/// zoomed out far enough that per-store labels would just clutter the map.
class MapboxStyleManager {
  MapboxStyleManager(this.mapboxMap, {this.onStoreTap});

  final MapboxMap mapboxMap;

  /// Called with a store id when its marker is tapped.
  final void Function(String storeId)? onStoreTap;

  PointAnnotationManager? _pointManager;

  // annotation id -> store id, to resolve taps back to a store.
  final Map<String, String> _annotationToStore = {};

  // Cached so selection highlighting can re-render without a new fetch.
  List<StoreEntity> _stores = [];
  String? _selectedStoreId;

  /// Below this zoom, markers collapse to plain dots (no icon/name) so a
  /// dense viewport doesn't turn into an unreadable wall of labels. Matches
  /// the "street level" threshold `world_map_page.dart` already uses for its
  /// fetch-radius calculation.
  static const double _expandZoomThreshold = 15;
  bool _collapsed = false;

  /// `PointAnnotationOptions.image` takes raw PNG bytes with no pixel-ratio
  /// metadata, so the native SDK renders roughly 1 image pixel per physical
  /// screen pixel. Without correcting for this, our canvas size constants
  /// (chosen as if they were logical/dp units) render at `1 / devicePixelRatio`
  /// of their intended size. Every generated bitmap is scaled by this factor
  /// to compensate.
  final double _dpr =
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  // Generated marker bitmaps, keyed by a signature of everything that
  // affects their pixels — avoids re-drawing + re-encoding a PNG for every
  // store on every render (camera move, socket upsert, selection change,
  // zoom-level toggle).
  final Map<String, Uint8List> _bitmapCache = {};

  // Decoded logo images, keyed by URL, so a logo is only fetched/decoded once
  // even though it's redrawn into a fresh bitmap whenever a store's other
  // signature fields change.
  final Map<String, ui.Image> _logoImageCache = {};

  /// Creates annotation managers (once) and registers tap handling.
  Future<void> initializeStoreLayers() async {
    if (_pointManager == null) {
      _pointManager = await mapboxMap.annotations
          .createPointAnnotationManager();
      _pointManager!.tapEvents(
        onTap: (annotation) {
          final storeId = _annotationToStore[annotation.id];
          if (storeId != null) onStoreTap?.call(storeId);
        },
      );
    }

    await _render();
  }

  /// Replaces all markers with one per store.
  Future<void> updateGeoJsonSource(List<StoreEntity> stores) async {
    _stores = stores;
    await _render();
  }

  /// Highlights the selected store (and de-highlights the rest).
  Future<void> updateSelectedStore(String? selectedStoreId) async {
    _selectedStoreId = selectedStoreId;
    await _render();
  }

  /// Switches marker detail level when the camera crosses the zoom
  /// threshold. Cheap to call on every camera tick — it's a no-op unless the
  /// expanded/collapsed bucket actually flips.
  Future<void> updateZoom(double zoom) async {
    final collapsed = zoom < _expandZoomThreshold;
    if (collapsed == _collapsed) return;
    _collapsed = collapsed;
    await _render();
  }

  static const double _iconRadius = 12;
  static const double _labelGap = 4;
  static const double _labelPaddingH = 8;
  static const double _canvasHeight = 36;
  static const double _dotRadius = 7;
  static const double _selectedDotRadius = 9;

  String _signatureFor(StoreEntity s, bool selected) {
    if (_collapsed) {
      return '${s.id}|dot|$selected|${s.categoryId ?? s.id}';
    }
    return [
      s.id,
      'label',
      selected,
      s.categoryId ?? s.name,
      s.categoryName ?? '',
      s.logoUrl ?? '',
      s.isOpen?.toString() ?? '',
      s.rating?.toStringAsFixed(1) ?? '',
    ].join('|');
  }

  /// Fetches and decodes a logo image, caching by URL. Returns null (and
  /// leaves the caller to fall back to the category icon) on any failure — a
  /// broken/slow logo URL must never block marker rendering.
  Future<ui.Image?> _loadLogoImage(String url) async {
    final cached = _logoImageCache[url];
    if (cached != null) return cached;

    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _logoImageCache[url] = frame.image;
      return frame.image;
    } on Exception catch (e) {
      debugPrint('Failed to load merchant logo "$url": $e');
      return null;
    }
  }

  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintIconChipContent(
    Canvas canvas,
    StoreEntity store,
    Offset center,
    ui.Image? logoImage,
  ) {
    if (logoImage != null) {
      final clipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: _iconRadius - 2));
      canvas
        ..save()
        ..clipPath(clipPath);

      final srcSize = logoImage.width < logoImage.height
          ? logoImage.width.toDouble()
          : logoImage.height.toDouble();
      final src = Rect.fromCenter(
        center: Offset(logoImage.width / 2, logoImage.height / 2),
        width: srcSize,
        height: srcSize,
      );
      final dst = Rect.fromCircle(center: center, radius: _iconRadius - 2);
      canvas
        ..drawImageRect(logoImage, src, dst, Paint())
        ..restore();
      return;
    }

    _paintIcon(canvas, iconForStore(store), center, 14, Colors.white);
  }

  /// Small solid dot — the collapsed-zoom representation. Every merchant
  /// keeps its own dot (no clustering/counting), just without the icon or
  /// name label that would clutter a dense, zoomed-out viewport.
  Future<Uint8List> _createDotImage(StoreEntity store, bool isSelected) async {
    final radius = isSelected ? _selectedDotRadius : _dotRadius;
    final size = (radius + 4) * 2;
    final pixelSize = (size * _dpr).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelSize.toDouble(), pixelSize.toDouble()),
    )..scale(_dpr);
    final center = Offset(size / 2, size / 2);

    canvas
      ..drawCircle(
        center + const Offset(0, 1),
        radius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawCircle(center, radius, Paint()..color = colorForStore(store))
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.5,
      );

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelSize, pixelSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Icon chip + floating name label — the expanded-zoom representation.
  /// The bitmap pads the icon's right side to mirror the label+gap width on
  /// the left, so the icon lands exactly on the canvas's geometric center —
  /// letting the marker use plain [IconAnchor.CENTER] with no manual
  /// offset math.
  Future<Uint8List> _createLabelMarkerImage(
    StoreEntity store,
    bool isSelected,
  ) async {
    final logoUrl = store.logoUrl;
    final logoImage = logoUrl == null ? null : await _loadLogoImage(logoUrl);

    final rating = store.rating;
    final label = rating != null
        ? '${store.name} · ★${rating.toStringAsFixed(1)}'
        : store.name;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 220);

    final labelWidth = textPainter.width + _labelPaddingH * 2;
    final labelHeight = textPainter.height + 6;
    final leftBlockWidth = labelWidth + _labelGap;
    const iconDiameter = _iconRadius * 2;
    final canvasWidth = leftBlockWidth * 2 + iconDiameter;
    final iconCenter = Offset(canvasWidth / 2, _canvasHeight / 2);
    final pixelWidth = (canvasWidth * _dpr).ceil();
    final pixelHeight = (_canvasHeight * _dpr).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()),
    )..scale(_dpr);

    final baseColor = colorForStore(store);
    final labelBorderColor = isSelected ? Colors.white : baseColor;

    // Name label pill, to the left of the icon.
    final labelRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          iconCenter.dx - iconDiameter / 2 - _labelGap - labelWidth / 2,
          iconCenter.dy,
        ),
        width: labelWidth,
        height: labelHeight,
      ),
      Radius.circular(labelHeight / 2),
    );
    canvas
      ..drawRRect(
        labelRRect.shift(const Offset(0, 1)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRRect(labelRRect, Paint()..color = AppColors.ink)
      ..drawRRect(
        labelRRect,
        Paint()
          ..color = labelBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2 : 1.5,
      );
    textPainter.paint(
      canvas,
      Offset(
        labelRRect.left + _labelPaddingH,
        iconCenter.dy - textPainter.height / 2,
      ),
    );

    // Selection highlight ring behind the icon — the icon's own fill always
    // stays the category color, so selecting a merchant never hides which
    // category it belongs to.
    if (isSelected) {
      canvas.drawCircle(
        iconCenter,
        _iconRadius + 3,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Icon chip shadow + base circle.
    canvas
      ..drawCircle(
        iconCenter + const Offset(0, 2),
        _iconRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(iconCenter, _iconRadius, Paint()..color = baseColor)
      ..drawCircle(
        iconCenter,
        _iconRadius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.5,
      );

    _paintIconChipContent(canvas, store, iconCenter, logoImage);

    // Open/closed indicator, top-right of the icon chip. Omitted entirely
    // when unknown — never fabricate a status.
    final isOpen = store.isOpen;
    if (isOpen != null) {
      final statusCenter =
          iconCenter + const Offset(_iconRadius * 0.75, -_iconRadius * 0.75);
      canvas
        ..drawCircle(statusCenter, 5, Paint()..color = Colors.white)
        ..drawCircle(
          statusCenter,
          3.5,
          Paint()
            ..color = isOpen
                ? AppColors.status.success
                : AppColors.text.secondary,
        );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth, pixelHeight);
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
        final signature = _signatureFor(s, selected);

        final bytes =
            _bitmapCache[signature] ??
            await (_collapsed
                ? _createDotImage(s, selected)
                : _createLabelMarkerImage(s, selected));
        _bitmapCache[signature] = bytes;

        pointOptions.add(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(s.lng, s.lat)),
            image: bytes,
            iconAnchor: IconAnchor.CENTER,
          ),
        );
      }

      final createdPoints = await pointManager.createMulti(pointOptions);
      for (var i = 0; i < createdPoints.length && i < _stores.length; i++) {
        final ann = createdPoints[i];
        if (ann != null) _annotationToStore[ann.id] = _stores[i].id;
      }
    } on Exception catch (e, stack) {
      debugPrint('Failed to render store markers: $e\n$stack');
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
