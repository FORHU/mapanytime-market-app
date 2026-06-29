import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Renders store markers using a [CircleAnnotationManager]. We use annotations
/// (not a GeoJSON source + CircleLayer) because the annotation render path is
/// reliable across style reloads and avoids the source-update timing issues we
/// hit with style layers.
class MapboxStyleManager {
  MapboxStyleManager(this.mapboxMap, {this.onStoreTap});

  final MapboxMap mapboxMap;

  /// Called with a store id when its marker is tapped.
  final void Function(String storeId)? onStoreTap;

  CircleAnnotationManager? _circleManager;

  // annotation id -> store id, to resolve taps back to a store.
  final Map<String, String> _annotationToStore = {};

  // Cached so selection highlighting can re-render without a new fetch.
  List<StoreEntity> _stores = [];
  String? _selectedStoreId;

  static const int _redDot = 0xFFFF0000;
  static const int _selectedDot = 0xFF2196F3; // blue for the selected store
  static const int _white = 0xFFFFFFFF;

  /// Creates the annotation manager (once) and registers tap handling.
  /// Safe to call on every style load — the manager persists across reloads,
  /// and we simply re-render the current markers.
  Future<void> initializeStoreLayers() async {
    if (_circleManager == null) {
      _circleManager =
          await mapboxMap.annotations.createCircleAnnotationManager();
      _circleManager!.tapEvents(
        onTap: (annotation) {
          final storeId = _annotationToStore[annotation.id];
          if (storeId != null) onStoreTap?.call(storeId);
        },
      );
    }
    await _render();
    debugPrint('MapboxStyleManager: store annotation manager ready.');
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

  Future<void> _render() async {
    final manager = _circleManager;
    if (manager == null) {
      debugPrint('updateGeoJsonSource: annotation manager not ready yet.');
      return;
    }
    try {
      await manager.deleteAll();
      _annotationToStore.clear();

      if (_stores.isEmpty) {
        debugPrint('Rendered 0 store markers.');
        return;
      }

      final options = _stores.map((s) {
        final selected = s.id == _selectedStoreId;
        return CircleAnnotationOptions(
          geometry: Point(coordinates: Position(s.lng, s.lat)),
          circleColor: selected ? _selectedDot : _redDot,
          circleRadius: selected ? 11 : 8,
          circleStrokeWidth: 2,
          circleStrokeColor: _white,
        );
      }).toList();

      final created = await manager.createMulti(options);
      for (var i = 0; i < created.length && i < _stores.length; i++) {
        final ann = created[i];
        if (ann != null) _annotationToStore[ann.id] = _stores[i].id;
      }
      debugPrint('Rendered ${created.length} store markers.');
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
