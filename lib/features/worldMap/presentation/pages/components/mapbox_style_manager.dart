import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Renders store markers via a native `GeoJsonSource` + style layers instead
/// of `PointAnnotationManager` — this is what lets Mapbox's own collision
/// engine and zoom-interpolation run natively (no per-frame Dart work, no
/// full teardown/rebuild on every store-list or zoom change), which matters
/// once there are hundreds of densely-clustered stores.
///
/// Two layers share one source:
/// - [_dotLayerId]: a small always-visible colored dot per store. Circles
///   aren't part of Mapbox's collision system, so this never disappears —
///   it's the fallback shown wherever the photo card above it is hidden.
/// - [_iconLayerId]: the rounded-square photo/monogram card,
///   `iconAllowOverlap: false` so the native collision engine hides
///   whichever icons would overlap, revealing the dot underneath.
///
/// Card size scales with the device's screen width (adaptive, computed
/// once) and with camera zoom (native `iconSizeExpression`, smallest zoomed
/// out growing to full size by a comfortable zoom and staying there).
class MapboxStyleManager {
  MapboxStyleManager(
    this.mapboxMap, {
    required double screenWidth,
    this.onStoreTap,
  }) : _cardSize = sizeFor(screenWidth);

  final MapboxMap mapboxMap;

  /// Called with a store id when its marker (photo card or fallback dot)
  /// is tapped.
  final void Function(String storeId)? onStoreTap;

  List<StoreEntity> _stores = [];

  static const _sourceId = 'stores-source';
  static const _dotLayerId = 'stores-dot-layer';
  static const _iconLayerId = 'stores-icon-layer';

  // Zoom range the marker grows across, native to the icon layer's
  // iconSizeExpression below — smallest at/below _minScaleZoom, full size
  // by _maxScaleZoom (matches the zoom `_selectStore` flies to) and staying
  // there. Tuned through several rounds of on-device feedback; keep these
  // values if this file is ever touched again.
  static const double _minScaleZoom = 12;
  static const double _maxScaleZoom = 17;
  static const double _minScale = 0.5;
  static const double _maxScale = 1;

  /// Native zoom-interpolation expression for the icon layer's
  /// `iconSizeExpression` — computed on the GPU per frame, zero Dart-side
  /// cost. Exposed for testing the tuned stop values without needing a
  /// live `MapboxMap`.
  @visibleForTesting
  static List<Object> get iconSizeExpression => [
    'interpolate',
    ['linear'],
    ['zoom'],
    _minScaleZoom,
    _minScale,
    _maxScaleZoom,
    _maxScale,
  ];

  /// `PointAnnotationOptions.image` took raw PNG bytes with no pixel-ratio
  /// metadata; `addStyleImage`'s `scale` parameter is the equivalent for
  /// registered style images (like `@2x`/`@3x` asset scales) — it's what
  /// maps the bitmap's raw pixel dimensions back to logical/dp size, so it
  /// must be passed alongside the bitmap, not just used to size the canvas.
  final double _dpr =
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  // Card size scales with screen width (clamped) so it stays legible on
  // small phones without dominating large ones, instead of one fixed dp
  // size for every device. This is the single bitmap size every store's
  // card is drawn at; the icon layer's iconSizeExpression scales it from
  // there per zoom level.
  static const double _widthFraction = 0.21;
  static const double _minCardWidth = 64;
  static const double _maxCardWidth = 92;

  @visibleForTesting
  static ({double width, double height}) sizeFor(double screenWidth) {
    final width = (screenWidth * _widthFraction).clamp(
      _minCardWidth,
      _maxCardWidth,
    );
    return (width: width, height: width);
  }

  final ({double width, double height}) _cardSize;

  static const double _cardRadius = AppRadius.sm;
  static const double _statusBadgeRadius = 5;

  // Registered style-image ids (content signatures) already uploaded via
  // addStyleImage — style-scoped, so this (and _liveSignatures below) must
  // be cleared and everything re-registered on every initializeStoreLayers
  // call, since a style reload (basemap switch) wipes custom images/
  // sources/layers along with it.
  final Set<String> _registeredImageIds = {};

  // storeId -> "iconId|lat|lng", the last state actually pushed to the
  // source. Lets updateGeoJsonSource diff instead of resending everything.
  final Map<String, String> _liveSignatures = {};

  // Decoded photo images, keyed by URL, so a photo is only fetched/decoded
  // once even though it's redrawn into a fresh bitmap whenever a store's
  // other signature fields change.
  final Map<String, ui.Image> _photoImageCache = {};

  /// Creates the source/layers/tap interactions. Must run its full setup
  /// every time, not just once — none of this survives a style reload
  /// (`loadStyleURI`, used by the basemap switcher), and this is already
  /// called again on every style load by `world_map_page.dart`.
  Future<void> initializeStoreLayers() async {
    _registeredImageIds.clear();
    _liveSignatures.clear();

    await mapboxMap.style.addSource(
      GeoJsonSource(
        id: _sourceId,
        data: '{"type":"FeatureCollection","features":[]}',
        // generateId intentionally left unset — partial updates
        // (add/update/removeGeoJSONSourceFeatures) require our own stable
        // string ids (store.id), not Mapbox-generated ones.
      ),
    );

    await mapboxMap.style.addLayer(
      CircleLayer(
        id: _dotLayerId,
        sourceId: _sourceId,
        circleRadius: 4,
        circleColorExpression: ['get', 'color'],
        circleStrokeWidth: 1,
        circleStrokeColor: Colors.white.toARGB32(),
      ),
    );

    await mapboxMap.style.addLayer(
      SymbolLayer(
        id: _iconLayerId,
        sourceId: _sourceId,
        iconImageExpression: ['get', 'iconId'],
        iconAllowOverlap: false,
        iconIgnorePlacement: false,
        iconAnchor: IconAnchor.CENTER,
        iconSizeExpression: iconSizeExpression,
        // Extra collision clearance around each card — without this,
        // Mapbox packs non-overlapping icons edge-to-edge, which in a
        // dense cluster still reads as visually crowded even though
        // nothing technically overlaps. This gives the collision engine
        // more reason to demote markers to the dot fallback, so fewer
        // full cards are visible at once.
        iconPadding: 12,
      ),
    );
    // Mapbox already cross-fades collision-driven icon appear/disappear by
    // default, but the global default (300ms/0ms) reads as an instant pop
    // during a fast pan. Overriding it per-layer (this must be a plain Map,
    // not a TransitionOptions object — the latter silently no-ops on both
    // Android and iOS) softens the fade and adds a delay before it starts,
    // so a marker that only briefly collides for a frame or two during a
    // gesture never visibly transitions at all. The dot layer needs no
    // change — it's always opaque, so it's simply revealed as the icon
    // above it fades out.
    await mapboxMap.style.setStyleLayerProperty(
      _iconLayerId,
      'icon-opacity-transition',
      {'duration': 350, 'delay': 150},
    );

    // Registered on both layers: a collision-suppressed icon isn't
    // hit-testable, so a store currently showing only as a dot must still
    // be tappable via the dot layer. stopPropagation (default true) means
    // tapping a visible card — sitting on its own dot — fires only the
    // card's handler, not both.
    mapboxMap
      ..addInteraction(
        TapInteraction(
          FeaturesetDescriptor(layerId: _iconLayerId),
          _handleTap,
        ),
        interactionID: '$_iconLayerId-tap',
      )
      ..addInteraction(
        TapInteraction(FeaturesetDescriptor(layerId: _dotLayerId), _handleTap),
        interactionID: '$_dotLayerId-tap',
      );

    await updateGeoJsonSource(_stores);
  }

  void _handleTap(
    TypedFeaturesetFeature<FeaturesetDescriptor> feature,
    MapContentGestureContext context,
  ) {
    final storeId = feature.properties['storeId'] as String?;
    if (storeId != null) onStoreTap?.call(storeId);
  }

  /// Diffs the new store list against what's currently on the source and
  /// applies only the add/update/remove needed — untouched stores are
  /// skipped entirely rather than resent.
  Future<void> updateGeoJsonSource(List<StoreEntity> stores) async {
    _stores = stores;
    final style = mapboxMap.style;

    final newIds = <String>{};
    final toAdd = <Feature>[];
    final toUpdate = <Feature>[];
    final toRegister = <(String iconId, StoreEntity store)>[];

    for (final store in stores) {
      newIds.add(store.id);
      final iconId = _iconIdFor(store);
      if (!_registeredImageIds.contains(iconId)) {
        toRegister.add((iconId, store));
      }

      final renderSignature = _renderSignatureFor(store, iconId);
      final previous = _liveSignatures[store.id];
      if (previous == null) {
        toAdd.add(_featureFor(store, iconId));
      } else if (previous != renderSignature) {
        toUpdate.add(_featureFor(store, iconId));
      }
      _liveSignatures[store.id] = renderSignature;
    }

    final removedIds = _liveSignatures.keys
        .where((id) => !newIds.contains(id))
        .toList()
      ..forEach(_liveSignatures.remove);

    try {
      // Register every new/changed bitmap concurrently — a cache miss means
      // a real network fetch for the store's photo, and awaiting those
      // sequentially in a dense viewport is the difference between a
      // near-instant render and one that visibly stalls.
      await Future.wait(
        toRegister.map((entry) => _registerImage(entry.$1, entry.$2)),
      );

      if (toAdd.isNotEmpty) {
        await style.addGeoJSONSourceFeatures(_sourceId, '', toAdd);
      }
      if (toUpdate.isNotEmpty) {
        await style.updateGeoJSONSourceFeatures(_sourceId, '', toUpdate);
      }
      if (removedIds.isNotEmpty) {
        await style.removeGeoJSONSourceFeatures(_sourceId, '', removedIds);
      }
    } on Exception catch (e, stack) {
      debugPrint('Failed to update store markers: $e\n$stack');
    }
  }

  Feature _featureFor(StoreEntity store, String iconId) => Feature(
    id: store.id,
    geometry: Point(coordinates: Position(store.lng, store.lat)),
    properties: {
      'storeId': store.id,
      'iconId': iconId,
      'color': colorForStore(store).toARGB32(),
    },
  );

  String _renderSignatureFor(StoreEntity s, String iconId) =>
      '$iconId|${s.lat}|${s.lng}';

  String _iconIdFor(StoreEntity s) => [
    s.id,
    s.markerPhotoUrl ?? '',
    s.isOpen?.toString() ?? '',
    s.categoryId ?? s.name,
  ].join('|');

  Future<void> _registerImage(String iconId, StoreEntity store) async {
    if (_registeredImageIds.contains(iconId)) return;
    final mbxImage = await _createCardImage(store);
    await mapboxMap.style.addStyleImage(
      iconId,
      _dpr,
      mbxImage,
      false,
      const [],
      const [],
      null,
    );
    _registeredImageIds.add(iconId);
  }

  /// Fetches and decodes a marker photo, caching by URL. Returns null (and
  /// leaves the caller to fall back to the monogram card) on any failure — a
  /// broken/slow photo URL must never block marker rendering.
  Future<ui.Image?> _loadPhotoImage(String url) async {
    final cached = _photoImageCache[url];
    if (cached != null) return cached;

    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _photoImageCache[url] = frame.image;
      return frame.image;
    } on Exception catch (e) {
      debugPrint('Failed to load marker photo "$url": $e');
      return null;
    }
  }

  void _paintMonogram(
    Canvas canvas,
    StoreEntity store,
    Offset center,
    double height,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: monogramForStore(store),
        style: TextStyle(
          fontSize: height * 0.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// Rounded-square photo card, registered once per distinct visual
  /// signature via `addStyleImage`. Shows the merchant's photo when it has
  /// one, center-cropped to fill the card; otherwise a colored monogram
  /// card so every merchant is still identifiable at a glance. Selection is
  /// handled by a separate halo layer, not baked in here.
  Future<MbxImage> _createCardImage(StoreEntity store) async {
    final cardSize = _cardSize;
    const radius = _cardRadius;
    const badgeRadius = _statusBadgeRadius;

    final photoUrl = store.markerPhotoUrl;
    final photoImage = photoUrl == null
        ? null
        : await _loadPhotoImage(photoUrl);

    // Pads for the fixed-pixel shadow blur below — that amount doesn't
    // scale with card size, so neither does this.
    const padding = AppSpacing.sm;
    final canvasWidth = cardSize.width + padding;
    final canvasHeight = cardSize.height + padding;
    final pixelWidth = (canvasWidth * _dpr).ceil();
    final pixelHeight = (canvasHeight * _dpr).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()),
    )..scale(_dpr);

    final center = Offset(canvasWidth / 2, canvasHeight / 2);
    final cardRect = Rect.fromCenter(
      center: center,
      width: cardSize.width,
      height: cardSize.height,
    );
    final cardRRect = RRect.fromRectAndRadius(
      cardRect,
      const Radius.circular(radius),
    );

    // Drop shadow.
    canvas.drawRRect(
      cardRRect.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    if (photoImage != null) {
      canvas
        ..save()
        ..clipRRect(cardRRect);

      // Crop-to-cover the destination (like CSS object-fit: cover): trim
      // the source's wider dimension so it fills the card without
      // stretching.
      final destAspect = cardRect.width / cardRect.height;
      final srcAspect = photoImage.width / photoImage.height;
      double srcWidth;
      double srcHeight;
      if (srcAspect > destAspect) {
        srcHeight = photoImage.height.toDouble();
        srcWidth = srcHeight * destAspect;
      } else {
        srcWidth = photoImage.width.toDouble();
        srcHeight = srcWidth / destAspect;
      }
      final src = Rect.fromCenter(
        center: Offset(photoImage.width / 2, photoImage.height / 2),
        width: srcWidth,
        height: srcHeight,
      );
      canvas
        ..drawImageRect(photoImage, src, cardRect, Paint())
        ..restore();
    } else {
      canvas.drawRRect(cardRRect, Paint()..color = colorForStore(store));
      _paintMonogram(canvas, store, center, cardSize.height);
    }

    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Open/closed indicator, upper-right corner. Inset proportionally
    // (rather than pinned to the literal bounding-box corner) so it sits
    // near the rounded corner's curve instead of floating past it.
    // Omitted entirely when unknown — never fabricate a status.
    final isOpen = store.isOpen;
    if (isOpen != null) {
      final statusCenter =
          center +
          Offset(cardSize.width / 2 * 0.75, -cardSize.height / 2 * 0.75);
      canvas
        ..drawCircle(
          statusCenter,
          badgeRadius + 1.5,
          Paint()..color = Colors.white,
        )
        ..drawCircle(
          statusCenter,
          badgeRadius,
          Paint()
            ..color = isOpen
                ? AppColors.status.success
                : AppColors.text.secondary,
        );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth, pixelHeight);
    // The SDK's MbxImage.data doc comment claims raw RGBA, but the Android
    // plugin build actually decodes this via a native image decoder
    // (confirmed on-device: raw RGBA bytes produced "Failed to create
    // image decoder... unimplemented" then an NPE on a null Bitmap) — it
    // wants an encoded image, the same as PointAnnotationOptions.image
    // always did. Do not "fix" this back to rawRgba without retesting on
    // a real device.
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return MbxImage(
      width: pixelWidth,
      height: pixelHeight,
      data: byteData!.buffer.asUint8List(),
    );
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
