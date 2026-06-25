import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Data-layer extension of [StoreEntity] that knows how to deserialize the
/// JSON returned by the `/stores/nearby` endpoint.
class StoreModel extends StoreEntity {
  const StoreModel({
    required super.id,
    required super.name,
    required super.lat,
    required super.lng,
    required super.distance,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final locs = json['storeLocations'] as Map<String, dynamic>? ?? {};
    return StoreModel(
      id: json['id'] as String? ?? '',
      name: json['storeName'] as String? ?? 'Unknown Store',
      lat: (locs['latitude'] as num?)?.toDouble() ?? 0.0,
      lng: (locs['longitude'] as num?)?.toDouble() ?? 0.0,
      distance: (json['DistanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
    'distance': distance,
  };
}
