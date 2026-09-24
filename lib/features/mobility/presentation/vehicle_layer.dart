import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mapanytime_market_app/features/mobility/data/mobility_remote_datasource.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// God's Eye on the map: one GeoJSON source + native layers for every live
/// vehicle, the same approach `MapboxStyleManager` uses for stores (no Flutter
/// widget per vehicle).
///
/// Types with a `markerIconUrl` render as that icon; the rest as a dot, so an
/// admin-added type shows up with no app release.
class VehicleLayer {
  VehicleLayer(this.mapboxMap);

  final MapboxMap mapboxMap;

  static const _sourceId = 'vehicles-source';
  static const _dotLayerId = 'vehicles-dot-layer';
  static const _iconLayerId = 'vehicles-icon-layer';
  static const double _iconSize = 36;

  /// At most one source push per this long — at 100 vehicles pinging every 5s
  /// the socket delivers ~20 events/s, and each push re-sends the collection.
  static const _renderGap = Duration(seconds: 1);

  Iterable<LiveVehicle> _pending = const [];
  Timer? _renderTimer;
  bool _ready = false;

  /// Adds the source, layers and type icons. Like the store layers, none of
  /// this survives a style reload, so it runs on every style load.
  Future<void> initialize(List<VehicleType> types) async {
    _ready = false;
    final style = mapboxMap.style;

    final iconCodes = <String>[];
    await Future.wait(
      types.where((t) => t.markerIconUrl != null).map((t) async {
        final image = await _loadIcon(t.markerIconUrl!);
        if (image == null) return;
        await style.addStyleImage(
          t.code,
          ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
          image,
          false,
          const [],
          const [],
          null,
        );
        iconCodes.add(t.code);
      }),
    );
    final hasIcon = [
      'in',
      ['get', 'typeCode'],
      ['literal', iconCodes],
    ];

    await style.addSource(
      GeoJsonSource(id: _sourceId, data: _collection(const [])),
    );
    await style.addLayer(
      CircleLayer(
        id: _dotLayerId,
        sourceId: _sourceId,
        filter: ['!', hasIcon],
        circleRadius: 7,
        circleColor: AppColors.ink.toARGB32(),
        circleStrokeWidth: 2,
        circleStrokeColor: Colors.white.toARGB32(),
      ),
    );
    await style.addLayer(
      SymbolLayer(
        id: _iconLayerId,
        sourceId: _sourceId,
        filter: hasIcon,
        iconImageExpression: ['get', 'typeCode'],
        // Live vehicles are the point of this layer — never hide one to
        // make room for a label or another vehicle.
        iconAllowOverlap: true,
      ),
    );

    _ready = true;
    await _flush();
  }

  /// Queues [vehicles] as the full set to show; pushes at most every
  /// [_renderGap].
  void render(Iterable<LiveVehicle> vehicles) {
    _pending = vehicles;
    if (_renderTimer?.isActive ?? false) return;
    unawaited(_flush());
    _renderTimer = Timer(_renderGap, () => unawaited(_flush()));
  }

  void dispose() => _renderTimer?.cancel();

  Future<void> _flush() async {
    if (!_ready) return;
    try {
      await mapboxMap.style.setStyleSourceProperty(
        _sourceId,
        'data',
        _collection(_pending),
      );
    } on Exception catch (e) {
      debugPrint('Failed to update vehicles: $e');
    }
  }

  static String _collection(Iterable<LiveVehicle> vehicles) => jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      for (final v in vehicles)
        {
          'type': 'Feature',
          'id': v.id,
          'geometry': {
            'type': 'Point',
            'coordinates': [v.lng, v.lat],
          },
          'properties': {'typeCode': v.typeCode, 'plate': v.plateNumber},
        },
    ],
  });

  /// Fetches, downsizes and PNG-encodes an icon. Null on any failure — a
  /// broken icon URL falls back to the dot rather than hiding the vehicle.
  static Future<MbxImage?> _loadIcon(String url) async {
    try {
      final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
      final file = await DefaultCacheManager().getSingleFile(url);
      final codec = await ui.instantiateImageCodec(
        await file.readAsBytes(),
        targetWidth: (_iconSize * dpr).round(),
      );
      final image = (await codec.getNextFrame()).image;
      // PNG, not raw RGBA: the Android plugin decodes this natively — see
      // MapboxStyleManager._rasterize.
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return MbxImage(
        width: image.width,
        height: image.height,
        data: bytes!.buffer.asUint8List(),
      );
    } on Exception catch (e) {
      debugPrint('Failed to load vehicle icon "$url": $e');
      return null;
    }
  }
}
