import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/mapbox_style_manager.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/store_clusterer.dart';

StoreEntity _store({
  MarkerDisplayMode markerDisplayMode = MarkerDisplayMode.photoCard,
  double? markerPrice,
  String? markerSubtitle,
}) => StoreEntity(
  id: 'store-1',
  name: 'Toyota Vios 2021',
  lat: 16.41,
  lng: 120.6,
  distance: 1,
  markerDisplayMode: markerDisplayMode,
  markerPrice: markerPrice,
  markerSubtitle: markerSubtitle,
);

void main() {
  group('MapboxStyleManager.iconIdFor', () {
    test('is stable for an unchanged store', () {
      final store = _store();
      expect(
        MapboxStyleManager.iconIdFor(store),
        MapboxStyleManager.iconIdFor(store),
      );
    });

    test('differs when markerDisplayMode differs', () {
      final photo = _store();
      final price = _store(markerDisplayMode: MarkerDisplayMode.priceCard);
      final label = _store(markerDisplayMode: MarkerDisplayMode.labelCard);

      final ids = {
        MapboxStyleManager.iconIdFor(photo),
        MapboxStyleManager.iconIdFor(price),
        MapboxStyleManager.iconIdFor(label),
      };
      expect(
        ids,
        hasLength(3),
        reason: 'each display mode must invalidate the cached bitmap',
      );
    });

    test('differs when markerPrice differs', () {
      final a = _store(
        markerDisplayMode: MarkerDisplayMode.priceCard,
        markerPrice: 1800,
      );
      final b = _store(
        markerDisplayMode: MarkerDisplayMode.priceCard,
        markerPrice: 3500,
      );
      expect(
        MapboxStyleManager.iconIdFor(a),
        isNot(MapboxStyleManager.iconIdFor(b)),
      );
    });

    test('differs when markerSubtitle differs', () {
      final a = _store(
        markerDisplayMode: MarkerDisplayMode.labelCard,
        markerSubtitle: 'Automatic · 45,000 km',
      );
      final b = _store(
        markerDisplayMode: MarkerDisplayMode.labelCard,
        markerSubtitle: 'Manual · 80,000 km',
      );
      expect(
        MapboxStyleManager.iconIdFor(a),
        isNot(MapboxStyleManager.iconIdFor(b)),
      );
    });

    test('differs when isSelected differs', () {
      final store = _store();
      expect(
        MapboxStyleManager.iconIdFor(store),
        isNot(MapboxStyleManager.iconIdFor(store, isSelected: true)),
      );
    });
  });

  group('MapboxStyleManager.iconIdForMarker', () {
    StoreCluster cluster({
      required int count,
      bool isBuildingGroup = false,
    }) => StoreCluster(
      id: 'cluster:0:0',
      stores: List.generate(count, (i) => _store()),
      lat: 14.6,
      lng: 120.98,
      isBuildingGroup: isBuildingGroup,
      label: 'Test Cluster',
    );

    test('is stable for an unchanged cluster', () {
      final c = cluster(count: 12);
      expect(
        MapboxStyleManager.iconIdForMarker(c),
        MapboxStyleManager.iconIdForMarker(c),
      );
    });

    test('differs between a count cluster and a building group', () {
      final count = cluster(count: 5);
      final building = cluster(count: 5, isBuildingGroup: true);
      expect(
        MapboxStyleManager.iconIdForMarker(count),
        isNot(MapboxStyleManager.iconIdForMarker(building)),
      );
    });

    test('differs when the member count differs', () {
      expect(
        MapboxStyleManager.iconIdForMarker(cluster(count: 5)),
        isNot(MapboxStyleManager.iconIdForMarker(cluster(count: 6))),
      );
    });

    test('differs when isTruncated differs, even at the same count', () {
      final c = cluster(count: 500);
      expect(
        MapboxStyleManager.iconIdForMarker(c),
        isNot(MapboxStyleManager.iconIdForMarker(c, isTruncated: true)),
      );
    });

    test('a StoreMarker delegates to the plain store iconIdFor', () {
      final store = _store();
      expect(
        MapboxStyleManager.iconIdForMarker(StoreMarker(store)),
        MapboxStyleManager.iconIdFor(store),
      );
    });

    test('a StoreMarker forwards isSelected to iconIdFor', () {
      final store = _store();
      expect(
        MapboxStyleManager.iconIdForMarker(
          StoreMarker(store),
          isSelected: true,
        ),
        MapboxStyleManager.iconIdFor(store, isSelected: true),
      );
    });
  });
}
