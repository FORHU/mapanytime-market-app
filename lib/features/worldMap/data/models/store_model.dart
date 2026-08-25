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
    super.markerPhotoUrl,
    super.rating,
    super.ratingCount,
    super.isOpen,
    super.markerDisplayMode,
    super.markerPrice,
    super.markerSubtitle,
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
      markerPhotoUrl: json['markerPhotoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt(),
      isOpen: json['isOpen'] as bool?,
      markerDisplayMode: _markerDisplayModeFromJson(
        json['markerDisplayMode'] as String?,
      ),
      markerPrice: (json['markerPrice'] as num?)?.toDouble(),
      markerSubtitle: json['markerSubtitle'] as String?,
    );
  }

  // Unknown/missing mode falls back to photoCard — matches the backend's
  // own column default, so an old client talking to a new API (or a
  // temporary bad value) degrades to today's behavior rather than crashing.
  static MarkerDisplayMode _markerDisplayModeFromJson(String? value) {
    switch (value) {
      case 'PRICE_CARD':
        return MarkerDisplayMode.priceCard;
      case 'LABEL_CARD':
        return MarkerDisplayMode.labelCard;
      default:
        return MarkerDisplayMode.photoCard;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'coordinates': {'lat': lat, 'lng': lng},
    'distanceKm': distance,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'logoUrl': logoUrl,
    'markerPhotoUrl': markerPhotoUrl,
    'rating': rating,
    'ratingCount': ratingCount,
    'isOpen': isOpen,
    'markerDisplayMode': markerDisplayMode.name,
    'markerPrice': markerPrice,
    'markerSubtitle': markerSubtitle,
  };
}
