import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/worldMap/data/models/store_model.dart';

void main() {
  group('StoreModel.fromJson', () {
    test('parses the /stores/nearby API shape correctly', () {
      final json = {
        'id': 'store-1',
        'storeName': 'Corner Shop',
        'distanceKm': 2.3,
        'coordinates': {'lat': 14.5995, 'lng': 120.9842},
        'address': {
          'city': 'Manila',
          'province': 'Metro Manila',
          'country': 'PH',
        },
        'markerPhotoUrl': 'https://cdn.example.com/stores/store-1/banner.jpg',
      };

      final model = StoreModel.fromJson(json);

      expect(model.id, 'store-1');
      expect(model.name, 'Corner Shop');
      expect(model.lat, 14.5995);
      expect(model.lng, 120.9842);
      expect(model.distance, 2.3);
      expect(
        model.markerPhotoUrl,
        'https://cdn.example.com/stores/store-1/banner.jpg',
      );
    });

    test('defaults markerPhotoUrl to null when absent', () {
      final model = StoreModel.fromJson(const {'id': 'store-4'});

      expect(model.markerPhotoUrl, isNull);
    });

    test('coerces integer coordinates and distance to double', () {
      final model = StoreModel.fromJson(const {
        'id': 'store-2',
        'storeName': 'Int Coords',
        'distanceKm': 5,
        'coordinates': {'lat': 14, 'lng': 121},
      });

      expect(model.lat, 14.0);
      expect(model.lng, 121.0);
      expect(model.distance, 5.0);
    });

    test('falls back to safe defaults when fields are missing', () {
      final model = StoreModel.fromJson(const {});

      expect(model.id, '');
      expect(model.name, 'Unknown Store');
      expect(model.lat, 0.0);
      expect(model.lng, 0.0);
      expect(model.distance, 0.0);
    });
  });

  test('toJson nests coordinates and uses distanceKm key', () {
    const model = StoreModel(
      id: 'store-3',
      name: 'Round Trip',
      lat: 1.5,
      lng: 2.5,
      distance: 3.5,
    );

    expect(model.toJson(), {
      'id': 'store-3',
      'name': 'Round Trip',
      'coordinates': {'lat': 1.5, 'lng': 2.5},
      'distanceKm': 3.5,
      'categoryId': null,
      'categoryName': null,
      'logoUrl': null,
      'markerPhotoUrl': null,
      'rating': null,
      'ratingCount': null,
      'isOpen': null,
      'markerDisplayMode': 'photoCard',
      'markerPrice': null,
      'markerSubtitle': null,
    });
  });
}
