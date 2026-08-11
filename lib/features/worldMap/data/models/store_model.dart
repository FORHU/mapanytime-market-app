import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Data-layer extension of [StoreEntity] that knows how to deserialize the
/// JSON returned by the `/stores/nearby` endpoint.
///
/// API shape:
/// ```json
/// {
///   "id": "...",
///   "storeName": "...",
///   "distanceKm": 2.3,
///   "coordinates": { "lat": 14.5995, "lng": 120.9842 },
///   "address": { "city": "...", "province": "...", "country": "..." }
/// }
/// ```
class StoreModel extends StoreEntity {
  const StoreModel({
    required super.id,
    required super.name,
    required super.lat,
    required super.lng,
    required super.distance,
    super.categoryId,
    super.categoryName,
    super.logoUrl,
    super.rating,
    super.ratingCount,
    super.isOpen,
  });

  // categoryId/categoryName/logoUrl/rating/ratingCount/isOpen aren't sent by
  // the backend yet — parsed defensively so they light up with no further
  // changes once the API starts including them (see Part B of the merchant
  // markers plan).
  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>? ?? {};
    return StoreModel(
      id: json['id'] as String? ?? '',
      name: json['storeName'] as String? ?? 'Unknown Store',
      lat: (coords['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (coords['lng'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      logoUrl: json['logoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt(),
      isOpen: json['isOpen'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'coordinates': {'lat': lat, 'lng': lng},
    'distanceKm': distance,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'logoUrl': logoUrl,
    'rating': rating,
    'ratingCount': ratingCount,
    'isOpen': isOpen,
  };
}
