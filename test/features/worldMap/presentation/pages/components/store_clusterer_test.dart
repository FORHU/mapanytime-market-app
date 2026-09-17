import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/store_clusterer.dart';

StoreEntity _store({
  required String id,
  required double lat,
  required double lng,
  String? address,
}) => StoreEntity(
  id: id,
  name: id,
  lat: lat,
  lng: lng,
  distance: 0,
  address: address,
);

void main() {
  group('StoreClusterer.cluster', () {
    test('a lone store passes through as a plain StoreMarker', () {
      final markers = StoreClusterer.cluster(
        [_store(id: 'a', lat: 14.5995, lng: 120.9842)],
        zoom: 14,
      );

      expect(markers, [isA<StoreMarker>()]);
    });

    test('drops stores at (0, 0) instead of clustering them together', () {
      final markers = StoreClusterer.cluster(
        [
          _store(id: 'a', lat: 0, lng: 0),
          _store(id: 'b', lat: 0, lng: 0),
          _store(id: 'c', lat: 14.5995, lng: 120.9842),
        ],
        zoom: 10,
      );

      expect(markers, hasLength(1));
      expect((markers.single as StoreMarker).store.id, 'c');
    });

    test('groups nearby stores into one cluster at low zoom', () {
      final markers = StoreClusterer.cluster(
        [
          _store(id: 'a', lat: 14.5995, lng: 120.9842),
          _store(id: 'b', lat: 14.6000, lng: 120.9850),
        ],
        zoom: 10,
      );

      expect(markers, hasLength(1));
      final cluster = markers.single as StoreCluster;
      expect(cluster.count, 2);
    });

    test('the same stores separate into singles at high zoom', () {
      final markers = StoreClusterer.cluster(
        [
          _store(id: 'a', lat: 14.5995, lng: 120.9842),
          _store(id: 'b', lat: 14.6000, lng: 120.9850),
        ],
        zoom: 20,
      );

      expect(markers, hasLength(2));
      expect(markers, everyElement(isA<StoreMarker>()));
    });

    test('stores far apart never cluster regardless of zoom', () {
      final markers = StoreClusterer.cluster(
        [
          _store(id: 'manila', lat: 14.5995, lng: 120.9842),
          _store(id: 'cebu', lat: 10.3157, lng: 123.8854),
        ],
        zoom: 4,
      );

      expect(markers, hasLength(2));
      expect(markers, everyElement(isA<StoreMarker>()));
    });

    test(
      'marks a cluster as a building group when members are within ~20m',
      () {
        final markers = StoreClusterer.cluster(
          [
            _store(id: 'a', lat: 14.0371, lng: 121.0223),
            // ~5.6m north — well inside the building threshold.
            _store(id: 'b', lat: 14.03715, lng: 121.0223),
          ],
          zoom: 15,
        );

        final cluster = markers.single as StoreCluster;
        expect(cluster.isBuildingGroup, isTrue);
      },
    );

    test(
      'does not mark a cluster as a building group when members are ~500m '
      'apart, even though they still share a cell at low zoom',
      () {
        final markers = StoreClusterer.cluster(
          [
            _store(id: 'a', lat: 14.5995, lng: 120.9842),
            // ~500m away — grouped at this zoom, but not "one building".
            _store(id: 'b', lat: 14.6040, lng: 120.9842),
          ],
          zoom: 10,
        );

        final cluster = markers.single as StoreCluster;
        expect(cluster.count, 2);
        expect(cluster.isBuildingGroup, isFalse);
      },
    );

    test('cluster id is stable across repeated calls for unchanged input', () {
      final stores = [
        _store(id: 'a', lat: 14.5995, lng: 120.9842),
        _store(id: 'b', lat: 14.6000, lng: 120.9850),
      ];

      final first =
          StoreClusterer.cluster(stores, zoom: 10).single as StoreCluster;
      final second =
          StoreClusterer.cluster(stores, zoom: 10).single as StoreCluster;

      expect(first.id, second.id);
    });

    test("labels a cluster with its members' most common address", () {
      final markers = StoreClusterer.cluster(
        [
          _store(
            id: 'a',
            lat: 14.5995,
            lng: 120.9842,
            address: 'SM Megamall Bldg A',
          ),
          _store(
            id: 'b',
            lat: 14.6000,
            lng: 120.9850,
            address: 'SM Megamall Bldg A',
          ),
        ],
        zoom: 10,
      );

      final cluster = markers.single as StoreCluster;
      expect(cluster.label, 'SM Megamall Bldg A');
    });

    test('falls back to a generic label when no member has an address', () {
      final markers = StoreClusterer.cluster(
        [
          _store(id: 'a', lat: 14.5995, lng: 120.9842),
          _store(id: 'b', lat: 14.6000, lng: 120.9850),
        ],
        zoom: 10,
      );

      final cluster = markers.single as StoreCluster;
      expect(cluster.label, '2 Stores');
    });
  });

  group('StoreClusterer.cellSizeMetersFor', () {
    test('shrinks as zoom increases', () {
      expect(
        StoreClusterer.cellSizeMetersFor(10),
        greaterThan(StoreClusterer.cellSizeMetersFor(18)),
      );
    });
  });

  group('formatStoreCountLabel', () {
    test('states the exact count when not truncated', () {
      expect(formatStoreCountLabel(12, isTruncated: false), '12 Stores');
    });

    test('appends a + when the underlying data was truncated', () {
      expect(formatStoreCountLabel(500, isTruncated: true), '500+ Stores');
    });
  });
}
