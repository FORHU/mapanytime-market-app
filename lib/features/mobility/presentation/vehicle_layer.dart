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

  /// One render cycle per this long — each push re-sends the whole collection.
  /// A cycle is a single push, or a glide of [_glideFrames] pushes.
  static const _renderGap = Duration(seconds: 1);
  static const _glideFrames = 5;

  /// Pings arrive every 10–15s, so a vehicle would otherwise jump tens of
  /// metres. Moves up to this far glide over one cycle; bigger ones (a
  /// snapshot, a reconnect) snap.
  static const _maxGlideDeg = 0.01;

  Map<String, LiveVehicle> _pending = const {};

  /// Where each vehicle was last drawn.
  Map<String, ({double lat, double lng})> _shown = const {};
  bool _cycling = false;
  bool _disposed = false;
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
        circleOpacityExpression: _stoppedDimmed,
        circleStrokeOpacityExpression: _stoppedDimmed,
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
        iconOpacityExpression: _stoppedDimmed,
        // Live vehicles are the point of this layer — never hide one to
        // make room for a label or another vehicle.
        iconAllowOverlap: true,
      ),
    );

    _ready = true;
    // The new source is empty: draw everyone in place, no glide.
    _shown = const {};
    _kick();
  }

  /// Queues [vehicles] as the full set to show. Drawn at most one cycle per
  /// [_renderGap].
  void render(Iterable<LiveVehicle> vehicles) {
    _pending = {for (final v in vehicles) v.id: v};
    _kick();
  }

  void dispose() => _disposed = true;

  void _kick() {
    if (_cycling || !_ready || _disposed) return;
    unawaited(_cycle());
  }

  /// Draws [_pending] (gliding what moved a little), then repeats while new
  /// positions arrived during the cycle.
  Future<void> _cycle() async {
    _cycling = true;
    try {
      for (;;) {
        final targets = _pending;
        final from = _shown;
        final glides = targets.values.any((v) {
          final p = from[v.id];
          return p != null && p != (lat: v.lat, lng: v.lng) && _near(p, v);
        });
        final frames = glides ? _glideFrames : 1;
        for (var i = 1; i <= frames; i++) {
          await _push(glideFrame(targets.values, from, i / frames));
          await Future<void>.delayed(_renderGap ~/ frames);
          if (_disposed || !_ready) return;
        }
        _shown = {
          for (final v in targets.values) v.id: (lat: v.lat, lng: v.lng),
        };
        if (identical(targets, _pending)) return;
      }
    } finally {
      _cycling = false;
    }
  }

  /// [vehicles] at fraction [t] of the way from where they were drawn
  /// ([from]) to where they are. New vehicles and long jumps snap.
  @visibleForTesting
  static List<(LiveVehicle, double lat, double lng)> glideFrame(
    Iterable<LiveVehicle> vehicles,
    Map<String, ({double lat, double lng})> from,
    double t,
  ) => [
    for (final v in vehicles)
      switch (from[v.id]) {
        final p? when _near(p, v) => (
          v,
          p.lat + (v.lat - p.lat) * t,
          p.lng + (v.lng - p.lng) * t,
        ),
        _ => (v, v.lat, v.lng),
      },
  ];

  static bool _near(({double lat, double lng}) p, LiveVehicle v) =>
      (v.lat - p.lat).abs() <= _maxGlideDeg &&
      (v.lng - p.lng).abs() <= _maxGlideDeg;

  Future<void> _push(List<(LiveVehicle, double, double)> frame) async {
    try {
      await mapboxMap.style.setStyleSourceProperty(
        _sourceId,
        'data',
        _collection(frame),
      );
    } on Exception catch (e) {
      debugPrint('Failed to update vehicles: $e');
    }
  }

  /// Parked vehicles fade back so the moving ones stand out.
  static const List<Object> _stoppedDimmed = [
    'case',
    ['get', 'stopped'],
    0.55,
    1.0,
  ];

  static String _collection(List<(LiveVehicle, double, double)> frame) =>
      jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          for (final (v, lat, lng) in frame)
            {
              'type': 'Feature',
              'id': v.id,
              'geometry': {
                'type': 'Point',
                'coordinates': [lng, lat],
              },
              'properties': {
                'typeCode': v.typeCode,
                'plate': v.plateNumber,
                'stopped': v.isStopped,
              },
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
