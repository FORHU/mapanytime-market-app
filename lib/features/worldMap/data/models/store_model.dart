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

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Unknown Store',
    lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
    'distance': distance,
  };
}
