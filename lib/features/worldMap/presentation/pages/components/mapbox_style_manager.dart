import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
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
  static const double _widthFraction = 0.15;
  static const double _minCardWidth = 48;
  static const double _maxCardWidth = 68;

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
        circleRadius: 6,
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
      final iconId = iconIdFor(store);
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

    final removedIds =
        _liveSignatures.keys.where((id) => !newIds.contains(id)).toList()
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
      'color': _hexColor(colorForStore(store)),
    },
  );

  // `circleColorExpression: ['get', 'color']` is a Style Spec data
  // expression — it needs a CSS color string, not a raw packed int. A bare
  // int silently fails to parse and circle-color falls back to its Style
  // Spec default (black), which is why every dot used to render black
  // regardless of category.
  String _hexColor(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  String _renderSignatureFor(StoreEntity s, String iconId) =>
      '$iconId|${s.lat}|${s.lng}';

  /// Content signature a registered bitmap is cached under — includes every
  /// field any `_paint*Card` method reads, so a change to any of them (e.g.
  /// switching marker display mode) invalidates the cache instead of
  /// leaving a stale bitmap on screen.
  @visibleForTesting
  static String iconIdFor(StoreEntity s) => [
    s.id,
    s.markerPhotoUrl ?? '',
    s.isOpen?.toString() ?? '',
    s.categoryId ?? s.name,
    s.markerDisplayMode.name,
    s.markerPrice?.toString() ?? '',
    s.markerSubtitle ?? '',
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

  // Fixed-pixel shadow blur doesn't scale with card size, so this padding
  // (reserved on every side of every bitmap so the blur has room) doesn't
  // either.
  static const double _shadowPadding = AppSpacing.sm;

  /// Marker card dispatcher — [StoreEntity.markerDisplayMode] picks which
  /// renderer runs. Each renderer sizes its own bitmap (a fixed square for
  /// [_renderPhotoCard], auto-width pills for the other two, since Mapbox's
  /// `addStyleImage` takes each icon's native size independently — there's
  /// no shared canvas dimension to agree on).
  Future<MbxImage> _createCardImage(StoreEntity store) {
    switch (store.markerDisplayMode) {
      case MarkerDisplayMode.priceCard:
        return _renderPriceCard(store);
      case MarkerDisplayMode.labelCard:
        return _renderLabelCard(store);
      case MarkerDisplayMode.photoCard:
        return _renderPhotoCard(store);
    }
  }

  /// Rasterizes a [logicalSize] card into an [MbxImage], with [_dpr]-aware
  /// pixel scaling and shadow padding shared by every display mode. [paint]
  /// draws into a card-space `Rect` positioned inside that padding.
  Future<MbxImage> _rasterize(
    ui.Size logicalSize,
    FutureOr<void> Function(Canvas canvas, Rect cardRect) paint,
  ) async {
    final canvasWidth = logicalSize.width + _shadowPadding;
    final canvasHeight = logicalSize.height + _shadowPadding;
    final pixelWidth = (canvasWidth * _dpr).ceil();
    final pixelHeight = (canvasHeight * _dpr).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()),
    )..scale(_dpr);

    final cardRect = Rect.fromLTWH(
      _shadowPadding / 2,
      _shadowPadding / 2,
      logicalSize.width,
      logicalSize.height,
    );

    await paint(canvas, cardRect);

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

  // Reuses the app's own small-raised-element shadow token instead of a
  // bespoke blur, so a marker's shadow matches the rest of the app's
  // floating chrome (search bar, chips, nav pill) instead of a harsher,
  // one-off value.
  void _drawCardShadow(Canvas canvas, RRect cardRRect) {
    final shadow = AppEffects.softShadow.first;
    canvas.drawRRect(cardRRect.shift(shadow.offset), shadow.toPaint());
  }

  void _drawCardStroke(Canvas canvas, RRect cardRRect, Color color) {
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // Open/closed indicator, upper-right corner. Inset proportionally (rather
  // than pinned to the literal bounding-box corner) so it sits near the
  // rounded corner's curve instead of floating past it. Omitted entirely
  // when unknown — never fabricate a status. Photo-card only: a price or
  // label listing (a rental night, a single car) doesn't carry the same
  // "open now" meaning a storefront does.
  void _paintStatusDot(
    Canvas canvas,
    StoreEntity store,
    Offset center,
    ({double width, double height}) cardSize,
  ) {
    final isOpen = store.isOpen;
    if (isOpen == null) return;
    final statusCenter =
        center + Offset(cardSize.width / 2 * 0.75, -cardSize.height / 2 * 0.75);
    canvas
      ..drawCircle(
        statusCenter,
        _statusBadgeRadius + 1.5,
        Paint()..color = Colors.white,
      )
      ..drawCircle(
        statusCenter,
        _statusBadgeRadius,
        Paint()
          ..color = isOpen
              ? AppColors.status.success
              : AppColors.text.secondary,
      );
  }

  /// Rounded-square photo card, fixed at [_cardSize]. Shows the merchant's
  /// photo, center-cropped to fill the card; otherwise a colored monogram
  /// card so every merchant is still identifiable at a glance.
  Future<MbxImage> _renderPhotoCard(StoreEntity store) {
    final size = ui.Size(_cardSize.width, _cardSize.height);
    return _rasterize(size, (canvas, cardRect) async {
      final cardRRect = RRect.fromRectAndRadius(
        cardRect,
        const Radius.circular(_cardRadius),
      );
      final center = cardRect.center;
      _drawCardShadow(canvas, cardRRect);

      final photoUrl = store.markerPhotoUrl;
      final photoImage = photoUrl == null
          ? null
          : await _loadPhotoImage(photoUrl);

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
        _paintMonogram(canvas, store, center, cardRect.height);
      }

      _drawCardStroke(canvas, cardRRect, Colors.white);
      _paintStatusDot(canvas, store, center, _cardSize);
    });
  }

  static final _priceFormat = NumberFormat.decimalPattern();

  /// Airbnb-style price pill for rentals/hotels: a white pill sized to fit
  /// the price text (not the square photo-card footprint), bold dark text,
  /// no photo. Falls back to the store name if a price hasn't been set, so
  /// a misconfigured store never renders blank.
  Future<MbxImage> _renderPriceCard(StoreEntity store) {
    final price = store.markerPrice;
    final label = price == null ? store.name : '₱${_priceFormat.format(price)}';

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: _cardSize.height * 0.24,
          fontWeight: FontWeight.w700,
          color: AppColors.text.primary,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    const paddingH = AppSpacing.sm + AppSpacing.xs;
    const paddingV = AppSpacing.xs + 2;
    final size = ui.Size(
      textPainter.width + paddingH * 2,
      textPainter.height + paddingV * 2,
    );

    return _rasterize(size, (canvas, cardRect) {
      final cardRRect = RRect.fromRectAndRadius(
        cardRect,
        Radius.circular(cardRect.height / 2),
      );
      _drawCardShadow(canvas, cardRRect);
      canvas.drawRRect(cardRRect, Paint()..color = AppColors.ui.surface);
      _drawCardStroke(canvas, cardRRect, AppColors.ui.borderHairline);
      textPainter.paint(
        canvas,
        cardRect.center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    });
  }

  /// Classifieds-style label card for second-hand marketplace items: a
  /// category-colored icon badge beside the item's own name (for a
  /// single-item listing, `storeName` *is* the item, e.g. "Toyota Vios
  /// 2021") over a smaller spec/year subtitle. Auto-sized to fit both
  /// lines rather than the square photo-card footprint, visually distinct
  /// from the plain white price pill.
  Future<MbxImage> _renderLabelCard(StoreEntity store) {
    final badgeDiameter = _cardSize.height * 0.5;
    final maxTextWidth = _cardSize.width * 1.6;

    final titlePainter = TextPainter(
      text: TextSpan(
        text: store.name,
        style: TextStyle(
          fontSize: _cardSize.height * 0.19,
          fontWeight: FontWeight.w700,
          color: AppColors.text.primary,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxTextWidth);

    final subtitle = store.markerSubtitle;
    final subtitlePainter = subtitle == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: subtitle,
              style: TextStyle(
                fontSize: _cardSize.height * 0.15,
                fontWeight: FontWeight.w500,
                color: AppColors.text.secondary,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: maxTextWidth));

    const paddingH = AppSpacing.sm;
    const gapIconText = AppSpacing.xs + 2;
    const textGap = 2.0;

    final textBlockWidth = subtitlePainter == null
        ? titlePainter.width
        : (titlePainter.width > subtitlePainter.width
              ? titlePainter.width
              : subtitlePainter.width);
    final textBlockHeight =
        titlePainter.height +
        (subtitlePainter == null ? 0 : textGap + subtitlePainter.height);

    final size = ui.Size(
      paddingH * 2 + badgeDiameter + gapIconText + textBlockWidth,
      (badgeDiameter > textBlockHeight ? badgeDiameter : textBlockHeight) +
          AppSpacing.xs * 2,
    );

    return _rasterize(size, (canvas, cardRect) {
      final cardRRect = RRect.fromRectAndRadius(
        cardRect,
        Radius.circular(cardRect.height / 2),
      );
      _drawCardShadow(canvas, cardRRect);
      canvas.drawRRect(cardRRect, Paint()..color = AppColors.ui.surface);
      _drawCardStroke(canvas, cardRRect, AppColors.ui.borderHairline);

      final badgeCenter = Offset(
        cardRect.left + paddingH + badgeDiameter / 2,
        cardRect.center.dy,
      );
      canvas.drawCircle(
        badgeCenter,
        badgeDiameter / 2,
        Paint()..color = colorForStore(store),
      );
      _paintCategoryGlyph(canvas, store, badgeCenter, badgeDiameter);

      final textLeft = cardRect.left + paddingH + badgeDiameter + gapIconText;
      var y = cardRect.center.dy - textBlockHeight / 2;
      titlePainter.paint(canvas, Offset(textLeft, y));
      if (subtitlePainter != null) {
        y += titlePainter.height + textGap;
        subtitlePainter.paint(canvas, Offset(textLeft, y));
      }
    });
  }

  /// Paints a category glyph (e.g. the automotive/electronics icon) centered
  /// in the label card's badge — the same trick `Icon` widgets use
  /// internally, painting the icon font's glyph directly via `TextPainter`
  /// since there's no widget tree here, only a raw `Canvas`.
  void _paintCategoryGlyph(
    Canvas canvas,
    StoreEntity store,
    Offset center,
    double diameter,
  ) {
    final icon = iconForStore(store);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: diameter * 0.55,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: AppColors.text.onInk,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
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
