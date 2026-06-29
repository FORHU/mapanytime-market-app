import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_marker.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxStyleManager {
  MapboxStyleManager(this.mapboxMap);
  final MapboxMap mapboxMap;

  // Kept so we can update its data later. addSource() binds the source to the
  // style; the instance returned by getSource() is NOT bound, so its
  // updateGeoJSON() silently no-ops — we must reuse this bound reference.
  GeoJsonSource? _storesSource;

  Future<void> initializeStoreLayers() async {
    // Always tear down and rebuild. Mapbox fires onStyleLoaded multiple times
    // (e.g. when remote glyph/tile data resolves) and a stale "source exists"
    // guard would skip layer registration, leaving the map blank.
    await _removeLayers();

    // Plain (non-clustered) GeoJSON source via the typed API. Every store
    // renders as its own point; Mapbox draws the whole set on the GPU.
    _storesSource = GeoJsonSource(
      id: 'stores_source',
      data: jsonEncode({
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      }),
    );
    await mapboxMap.style.addSource(_storesSource!);

    // Add the red dot layer FIRST — before any image/ribbon code that could
    // throw — so the dots are guaranteed even if the ribbon setup fails.
    // Colors are ARGB ints (0xAARRGGBB).
    await mapboxMap.style.addLayer(
      CircleLayer(
        id: 'store-point',
        sourceId: 'stores_source',
        circleColor: 0xFFFF0000, // opaque red
        circleRadius: 8,
        circleStrokeWidth: 2,
        circleStrokeColor: 0xFFFFFFFF, // white outline
      ),
    );

    // Register native ribbon image. Catch Error too (not just Exception):
    // getCustomMarkerBytes() uses a null-check `!` that throws a TypeError —
    // an Error — which `on Exception` would NOT catch, aborting init.
    try {
      final imageBytes = await StoreMarkerUtils.getCustomMarkerBytes();
      final image = MbxImage(width: 64, height: 64, data: imageBytes);

      try {
        await mapboxMap.style.removeStyleImage('store-ribbon-icon');
      } on Exception catch (_) {} // Ignore if it doesn't exist

      await mapboxMap.style.addStyleImage(
        'store-ribbon-icon',
        2, // scale
        image,
        false, // sdf
        [], // stretchX
        [], // stretchY
        null, // content
      );
      // Broad catch is deliberate: Mapbox can throw non-Exception Errors here
      // (e.g. a TypeError) that must not abort the rest of layer init.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint(
        'MapboxStyleManager: Warning: Failed to add store-ribbon image: $e',
      );
    }

    // Add native ribbon layer (visible only for the selected store)
    final ribbonLayerJson = jsonEncode({
      'id': 'store-ribbon',
      'type': 'symbol',
      'source': 'stores_source',
      // Hidden by default until a store is selected
      'filter': [
        '==',
        ['get', 'storeId'],
        'NONE',
      ],
      'layout': {
        'icon-image': 'store-ribbon-icon',
        'icon-text-fit': 'both',
        'icon-text-fit-padding': [8, 12, 8, 12],
        'text-field': ['get', 'name'],
        'text-font': ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        'text-size': 14,
        'text-anchor': 'bottom',
        'icon-anchor': 'bottom',
      },
      'paint': {
        'text-color': '#ffffff',
      },
    });
    try {
      await mapboxMap.style.addStyleLayer(ribbonLayerJson, null);
      // Broad catch is deliberate: Mapbox can throw non-Exception Errors here
      // (e.g. a TypeError) that must not abort the rest of layer init.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('MapboxStyleManager: Warning: ribbon layer failed: $e');
    }

    debugPrint('MapboxStyleManager: Store layers initialized.');
  }

  /// Removes all custom layers and the GeoJSON source, ignoring errors if
  /// they don't exist (e.g. on first load or after a style wipe).
  Future<void> _removeLayers() async {
    for (final layerId in [
      'store-ribbon',
      'store-point',
    ]) {
      try {
        if (await mapboxMap.style.styleLayerExists(layerId)) {
          await mapboxMap.style.removeStyleLayer(layerId);
        }
      } on Exception catch (_) {}
    }
    try {
      if (await mapboxMap.style.styleSourceExists('stores_source')) {
        await mapboxMap.style.removeStyleSource('stores_source');
      }
    } on Exception catch (_) {}
  }

  Future<void> updateSelectedStore(String? selectedStoreId) async {
    try {
      // Ribbon shows only for the selected store
      final ribbonFilter = [
        '==',
        ['get', 'storeId'],
        selectedStoreId ?? 'NONE',
      ];

      // Red dot shows for every non-selected store
      final dotFilter = [
        '!=',
        ['get', 'storeId'],
        selectedStoreId ?? 'NONE',
      ];

      await mapboxMap.style.setStyleLayerProperty(
        'store-ribbon',
        'filter',
        jsonEncode(ribbonFilter),
      );

      await mapboxMap.style.setStyleLayerProperty(
        'store-point',
        'filter',
        jsonEncode(dotFilter),
      );
    } on Exception catch (e) {
      debugPrint('Failed to update selected store filter: $e');
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

  Future<void> updateGeoJsonSource(List<StoreEntity> stores) async {
    final features = stores.map((s) {
      return {
        'type': 'Feature',
        'properties': {
          'storeId': s.id,
          'name': s.name,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [s.lng, s.lat],
        },
      };
    }).toList();

    final geoJson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    final source = _storesSource;
    if (source == null) return;
    try {
      // Update through the BOUND source created in initializeStoreLayers.
      // (getSource() returns an UNBOUND instance whose updateGeoJSON no-ops.)
      await source.updateGeoJSON(jsonEncode(geoJson));
      debugPrint('Updated stores_source with ${stores.length} stores.');
    } on Exception catch (e, stack) {
      debugPrint('Failed to update geojson source: $e\n$stack');
    }
  }
}
