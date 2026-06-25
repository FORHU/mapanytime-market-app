import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxStyleManager {

  MapboxStyleManager(this.mapboxMap);
  final MapboxMap mapboxMap;

  Future<void> initializeClusters() async {
    final sourceJson = jsonEncode({
      'type': 'geojson',
      'data': {
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      },
      'cluster': true,
      'clusterMaxZoom': 14,
      'clusterRadius': 50
    });

    await mapboxMap.style.addStyleSource('stores_source', sourceJson);

    // Add cluster circles layer
    final clusterLayerJson = jsonEncode({
      'id': 'clusters',
      'type': 'circle',
      'source': 'stores_source',
      'filter': ['has', 'point_count'],
      'paint': {
        'circle-color': [
          'step',
          ['get', 'point_count'],
          '#51bbd6',
          10,
          '#f1f075',
          50,
          '#f28cb1'
        ],
        'circle-radius': ['step', ['get', 'point_count'], 20, 10, 30, 50, 40]
      }
    });
    await mapboxMap.style.addStyleLayer(clusterLayerJson, null);

    // Add cluster count text layer
    final clusterCountLayerJson = jsonEncode({
      'id': 'cluster-count',
      'type': 'symbol',
      'source': 'stores_source',
      'filter': ['has', 'point_count'],
      'layout': {
        'text-field': ['get', 'point_count_abbreviated'],
        'text-font': ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        'text-size': 12
      }
    });
    await mapboxMap.style.addStyleLayer(clusterCountLayerJson, null);

    // Add unclustered point layer
    final unclusteredPointLayerJson = jsonEncode({
      'id': 'unclustered-point',
      'type': 'circle',
      'source': 'stores_source',
      'filter': ['!', ['has', 'point_count']],
      'paint': {
        'circle-color': '#ff0000',
        'circle-radius': 8,
        'circle-stroke-width': 2,
        'circle-stroke-color': '#ffffff'
      }
    });
    await mapboxMap.style.addStyleLayer(unclusteredPointLayerJson, null);
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
    if (stores.isEmpty) return;

    final features = stores.map((s) {
      return {
        'type': 'Feature',
        'properties': {
          'storeId': s.id,
          'name': s.name,
          'cluster': false, // explicitly mark unclustered

        },
        'geometry': {
          'type': 'Point',
          'coordinates': [s.lng, s.lat]
        }
      };
    }).toList();

    final geoJson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    try {
      final sourceExists =
          await mapboxMap.style.styleSourceExists('stores_source');
      if (sourceExists) {
        await mapboxMap.style.setStyleSourceProperty(
          'stores_source',
          'data',
          jsonEncode(geoJson),
        );
        debugPrint(
          'Updated Mapbox GeoJSON source with ${stores.length} stores.',
        );
      }
    } on Exception catch (e, stack) {
      debugPrint('Failed to update geojson source: $e\n$stack');
    }
  }
}
