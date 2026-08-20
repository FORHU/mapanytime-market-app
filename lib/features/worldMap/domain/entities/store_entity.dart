import 'package:equatable/equatable.dart';

/// Pure domain object — no JSON, no framework types. Equatable gives value
/// equality so two stores with the same fields compare equal.
class StoreEntity extends Equatable {
  const StoreEntity({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.distance,
    this.categoryId,
    this.categoryName,
    this.logoUrl,
    this.markerPhotoUrl,
    this.rating,
    this.ratingCount,
    this.isOpen,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  /// Distance from the query origin, in kilometres.
  final double distance;

  // The fields below are not sent by `/stores/nearby` yet — they stay null
  // until the backend exposes them. Marker/UI code must degrade gracefully
  // rather than fabricate a value when these are absent.
  final String? categoryId;
  final String? categoryName;
  final String? logoUrl;
  final String? markerPhotoUrl;
  final double? rating;
  final int? ratingCount;
  final bool? isOpen;

  @override
  List<Object?> get props => [
    id,
    name,
    lat,
    lng,
    distance,
    categoryId,
    categoryName,
    logoUrl,
    markerPhotoUrl,
    rating,
    ratingCount,
    isOpen,
  ];
}
