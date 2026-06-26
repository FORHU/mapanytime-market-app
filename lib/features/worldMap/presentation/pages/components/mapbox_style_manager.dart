import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_marker.dart';
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
      'clusterRadius': 50,
    });

    await mapboxMap.style.addStyleSource('stores_source', sourceJson);

    // Register native ribbon image
    final imageBytes = await StoreMarkerUtils.getCustomMarkerBytes();
    final image = MbxImage(width: 64, height: 64, data: imageBytes);
    await mapboxMap.style.addStyleImage(
      'store-ribbon',
      2, // scale
      image,
      false, // sdf
      [], // stretchX
      [], // stretchY
      null, // content
    );

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
          'rgba(81, 187, 214, 1)', // #51bbd6
          10,
          'rgba(241, 240, 117, 1)', // #f1f075
          50,
          'rgba(242, 140, 177, 1)', // #f28cb1
        ],
        'circle-radius': ['step', ['get', 'point_count'], 20, 10, 30, 50, 40],
      },
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
        'text-size': 12,
      },
    });
    await mapboxMap.style.addStyleLayer(clusterCountLayerJson, null);

    // Add red dot layer (visible for unclustered, non-selected points)
    final redDotLayerJson = jsonEncode({
      'id': 'unclustered-point',
      'type': 'circle',
      'source': 'stores_source',
      'filter': [
        'all',
        ['!', ['has', 'point_count']],
      ],
      'paint': {
        'circle-color': 'rgba(255, 0, 0, 1)',
        'circle-radius': 8,
        'circle-stroke-width': 2,
        'circle-stroke-color': 'rgba(255, 255, 255, 1)',
      },
    });
    await mapboxMap.style.addStyleLayer(redDotLayerJson, null);

    // Add native ribbon layer (visible only for the selected store)
    final ribbonLayerJson = jsonEncode({
      'id': 'unclustered-ribbon',
      'type': 'symbol',
      'source': 'stores_source',
      'filter': [
        'all',
        ['!', ['has', 'point_count']],
        // Hidden by default until a store is selected
        ['==', 'storeId', 'NONE'],
      ],
      'layout': {
        'icon-image': 'store-ribbon',
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
    await mapboxMap.style.addStyleLayer(ribbonLayerJson, null);
  }

  Future<void> updateSelectedStore(String? selectedStoreId) async {
    try {
      // Ribbon shows only for the selected store
      final ribbonFilter = [
        'all',
        ['!', ['has', 'point_count']],
        ['==', 'storeId', selectedStoreId ?? 'NONE'],
      ];

      // Red dot shows for all unclustered, non-selected stores
      final dotFilter = [
        'all',
        ['!', ['has', 'point_count']],
        ['!=', 'storeId', selectedStoreId ?? 'NONE'],
      ];

      await mapboxMap.style.setStyleLayerProperty(
        'unclustered-ribbon',
        'filter',
        jsonEncode(ribbonFilter),
      );

      await mapboxMap.style.setStyleLayerProperty(
        'unclustered-point',
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
    if (stores.isEmpty) return;

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
