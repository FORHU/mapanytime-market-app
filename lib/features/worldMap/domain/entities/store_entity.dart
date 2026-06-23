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
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  /// Distance from the query origin, in kilometres.
  final double distance;

  @override
  List<Object?> get props => [id, name, lat, lng, distance];
}
