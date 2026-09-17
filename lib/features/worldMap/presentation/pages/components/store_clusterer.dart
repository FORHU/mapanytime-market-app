import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// A store marker or a cluster of stores to render on the map, produced by
/// [StoreClusterer.cluster]. Sealed so every consumer (renderer, tap
/// handler) is forced to handle both cases explicitly rather than assuming
/// every feature on the map is a single store.
sealed class MapMarker {
  const MapMarker();
}

/// A single store, unaffected by clustering — rendered exactly as it always
/// has been.
class StoreMarker extends MapMarker {
  const StoreMarker(this.store);

  final StoreEntity store;
}

/// Two or more stores grouped together.
///
/// [isBuildingGroup] means the members sit within
/// [StoreClusterer.buildingGroupThresholdMeters] of each other — close
/// enough that no further zoom would usefully separate them. That is the
/// terminal state: rendered as a distinct "building" icon that opens a list
/// on tap rather than flying to a higher zoom.
class StoreCluster extends MapMarker {
  const StoreCluster({
    required this.id,
    required this.stores,
    required this.lat,
    required this.lng,
    required this.isBuildingGroup,
    required this.label,
  });

  /// Derived from the grid cell, not the camera or a random UUID — stable
  /// across frames as long as membership is unchanged, which is what lets
  /// `MapboxStyleManager.updateGeoJsonSource`'s add/update/remove diffing
  /// treat an unchanged cluster as untouched instead of remove-then-add.
  final String id;

  final List<StoreEntity> stores;
  final double lat;
  final double lng;
  final bool isBuildingGroup;

  /// Display heading for the cluster sheet: the most common non-empty
  /// [StoreEntity.address] among members, or a generic fallback when none
  /// have one.
  final String label;

  int get count => stores.length;
}

/// Groups stores into [MapMarker]s for a given camera zoom.
///
/// A pure function deliberately: no `MapboxMap`, no I/O, so it unit-tests
/// directly without a live map — mirroring `MapboxStyleManager.iconIdFor`'s
/// `@visibleForTesting` static pattern. Grid-based rather than pairwise
/// distance, so it stays O(n) per call: this can run on every camera-idle
/// event against up to 500 stores.
class StoreClusterer {
  const StoreClusterer._();

  /// Real-world spread below which a group counts as one building — see the
  /// "Building groups key on coordinate proximity" plan decision.
  /// Deliberately independent of zoom: it describes how close the stores
  /// actually are, not how the camera happens to be framed.
  static const double buildingGroupThresholdMeters = 20;

  /// Grid cell radius in logical pixels, matched to the marker card size so
  /// clusters roughly track visual crowding rather than an arbitrary fixed
  /// distance.
  static const double _clusterRadiusPixels = 60;

  static const double _metersPerDegreeLat = 111320;
  static const double _earthRadiusMeters = 6371000;

  /// Groups [stores] for the given [zoom]. Stores at exactly (0, 0) are
  /// dropped first: `StoreModel.fromJson` defaults missing coordinates to
  /// 0.0, so without this guard every coordinate-less store would bin
  /// together into a phantom cluster in the Gulf of Guinea.
  static List<MapMarker> cluster(
    List<StoreEntity> stores, {
    required double zoom,
  }) {
    final valid = stores.where((s) => s.lat != 0 || s.lng != 0).toList();
    if (valid.isEmpty) return const [];

    final cellSizeMeters = cellSizeMetersFor(zoom);
    // Longitude degrees shrink toward the poles; latitude degrees don't.
    // One reference latitude is enough for binning purposes — this never
    // needs to be geodetically exact, only consistent enough to group
    // stores that are visually close together.
    final metersPerDegreeLng =
        _metersPerDegreeLat * math.cos(valid.first.lat * math.pi / 180);

    final bins = <String, List<StoreEntity>>{};
    for (final store in valid) {
      final cellX =
          ((store.lng * metersPerDegreeLng) / cellSizeMeters).floor();
      final cellY =
          ((store.lat * _metersPerDegreeLat) / cellSizeMeters).floor();
      (bins[_binKey(cellX, cellY)] ??= []).add(store);
    }

    final markers = <MapMarker>[];
    for (final entry in bins.entries) {
      final members = entry.value;
      if (members.length == 1) {
        markers.add(StoreMarker(members.first));
        continue;
      }

      markers.add(
        StoreCluster(
          id: 'cluster:${entry.key}',
          stores: members,
          lat: _average(members.map((s) => s.lat)),
          lng: _average(members.map((s) => s.lng)),
          isBuildingGroup:
              _maxSpreadMeters(members) <= buildingGroupThresholdMeters,
          label: _labelFor(members),
        ),
      );
    }

    return markers;
  }

  static String _binKey(int cellX, int cellY) => '$cellX:$cellY';

  /// Grid cell size shrinks as zoom increases, so a cluster tracks a roughly
  /// constant on-screen radius instead of a constant real-world one —
  /// matching how the icon layer's own `iconSizeExpression` scales with
  /// zoom. Exposed for testing the tuned constants without a live map.
  @visibleForTesting
  static double cellSizeMetersFor(double zoom) {
    final metersPerPixel = 156543.03392 / math.pow(2, zoom);
    return _clusterRadiusPixels * metersPerPixel;
  }

  static double _average(Iterable<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static double _maxSpreadMeters(List<StoreEntity> members) {
    var maxMeters = 0.0;
    for (var i = 0; i < members.length; i++) {
      for (var j = i + 1; j < members.length; j++) {
        final meters = _haversineMeters(members[i], members[j]);
        if (meters > maxMeters) maxMeters = meters;
      }
    }
    return maxMeters;
  }

  static double _haversineMeters(StoreEntity a, StoreEntity b) {
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final h = sinLat * sinLat +
        math.cos(a.lat * math.pi / 180) *
            math.cos(b.lat * math.pi / 180) *
            sinLng *
            sinLng;
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  /// The most common non-empty address among members, so a cluster of
  /// stores sharing a real address reads as e.g. "SM Megamall Bldg A"
  /// rather than a bare count. Falls back to a generic heading when no
  /// member has an address — a blank `currentAddress` is common seller data,
  /// not a bug to surface.
  static String _labelFor(List<StoreEntity> members) {
    final counts = <String, int>{};
    for (final store in members) {
      final address = store.address;
      if (address == null) continue;
      counts[address] = (counts[address] ?? 0) + 1;
    }
    if (counts.isEmpty) return '${members.length} Stores';
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}

/// Formats a cluster's count for display.
///
/// [isTruncated] should be true only when this specific cluster's count
/// equals the controller's entire loaded store list *and* that list was
/// itself capped (`hasMore`) — the one case where a count is a lower bound
/// rather than exact. Showing "+" on every cluster whenever any part of the
/// viewport was truncated would be misleading in the other direction.
String formatStoreCountLabel(int count, {required bool isTruncated}) =>
    isTruncated ? '$count+ Stores' : '$count Stores';
