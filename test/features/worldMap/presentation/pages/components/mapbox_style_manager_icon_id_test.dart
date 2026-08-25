import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/mapbox_style_manager.dart';

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
  });
}
