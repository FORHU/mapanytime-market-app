import 'package:equatable/equatable.dart';

/// How a store's marker should render on the map. `photoCard` is the
/// default (photo, or a colored monogram fallback); `priceCard` is an
/// Airbnb-style price pill for rentals/hotels; `labelCard` is a
/// classifieds-style name+subtitle card for second-hand marketplace items.
enum MarkerDisplayMode { photoCard, priceCard, labelCard }

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
    this.markerDisplayMode = MarkerDisplayMode.photoCard,
    this.markerPrice,
    this.markerSubtitle,
    this.address,
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

  final MarkerDisplayMode markerDisplayMode;

  /// Used when [markerDisplayMode] is [MarkerDisplayMode.priceCard].
  final double? markerPrice;

  /// Used when [markerDisplayMode] is [MarkerDisplayMode.labelCard].
  final String? markerSubtitle;

  /// The seller-entered street address, e.g. "SM Megamall Bldg A". Free text,
  /// not a building identifier — used only as a display label. Grouping
  /// co-located stores must key on coordinates, not this string, since two
  /// sellers in the same building routinely type it differently.
  final String? address;

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
    markerDisplayMode,
    markerPrice,
    markerSubtitle,
    address,
  ];
}
