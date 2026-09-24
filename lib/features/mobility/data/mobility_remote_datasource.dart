import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;

/// A vehicle's latest broadcast position, as sent by `vehicle:moved` and
/// `GET /mobility/vehicles/live`.
class LiveVehicle {
  const LiveVehicle({
    required this.id,
    required this.plateNumber,
    required this.typeCode,
    required this.lat,
    required this.lng,
    required this.receivedAt,
    this.heading,
  });

  factory LiveVehicle.fromJson(Map<String, dynamic> json, {DateTime? now}) =>
      LiveVehicle(
        id: json['id'] as String,
        plateNumber: json['plateNumber'] as String? ?? '',
        typeCode: json['typeCode'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        receivedAt: now ?? DateTime.now(),
      );

  final String id;
  final String plateNumber;
  final String typeCode;
  final double lat;
  final double lng;
  final double? heading;

  /// Phone-clock time this position arrived — staleness is judged by this,
  /// not the driver's device clock, so clock skew can't keep a ghost alive.
  final DateTime receivedAt;
}

/// A transport mode. New ones are added by admins; the app renders whatever
/// comes back, keyed by [code].
class VehicleType {
  const VehicleType({
    required this.code,
    required this.name,
    this.markerIconUrl,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) => VehicleType(
    code: json['code'] as String,
    name: json['name'] as String? ?? '',
    markerIconUrl: json['markerIconUrl'] as String?,
  );

  final String code;
  final String name;
  final String? markerIconUrl;
}

/// The vehicle assigned to the signed-in driver.
class DriverVehicle {
  const DriverVehicle({required this.plateNumber, required this.typeName});

  factory DriverVehicle.fromJson(Map<String, dynamic> json) => DriverVehicle(
    plateNumber: json['plateNumber'] as String? ?? '',
    typeName:
        (json['vehicleType'] as Map?)?.cast<String, dynamic>()['name']
            as String? ??
        '',
  );

  final String plateNumber;
  final String typeName;
}

/// Mobility REST calls. Transport failures surface as the [ApiService]'s
/// typed exceptions.
class MobilityRemoteDataSource {
  MobilityRemoteDataSource(this._api);

  final ApiService _api;

  static Object? _data(dynamic response) =>
      response is Map ? response['data'] : null;

  static List<Map<String, dynamic>> _list(dynamic response) {
    final data = _data(response);
    return data is List
        ? data.map((e) => (e as Map).cast<String, dynamic>()).toList()
        : const [];
  }

  Future<List<VehicleType>> vehicleTypes() async => _list(
    await _api.get(ApiEndpoints.mobilityVehicleTypes),
  ).map(VehicleType.fromJson).toList();

  Future<List<LiveVehicle>> liveVehicles({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async => _list(
    await _api.get(
      ApiEndpoints.mobilityLiveVehicles,
      query: {'north': north, 'south': south, 'east': east, 'west': west},
    ),
  ).map(LiveVehicle.fromJson).toList();

  Future<DriverVehicle?> myVehicle() async {
    final data = _data(await _api.get(ApiEndpoints.mobilityMyVehicle));
    return data is Map
        ? DriverVehicle.fromJson(data.cast<String, dynamic>())
        : null;
  }

  /// [at] defaults to the fix's own time; the heartbeat passes "now" to say
  /// "still here" for a parked vehicle whose last fix has aged.
  Future<void> sendLocation(Position p, {DateTime? at}) =>
      _api.post(ApiEndpoints.mobilityTrackingLocation, {
        'lat': p.latitude,
        'lng': p.longitude,
        // Geolocator reports m/s and -1 for "unknown"; the API takes km/h.
        if (p.speed >= 0) 'speed': (p.speed * 3.6).clamp(0, 160),
        if (p.heading >= 0) 'heading': p.heading,
        'timestamp': (at ?? p.timestamp).millisecondsSinceEpoch,
      });

  Future<void> stopTracking() => _api.post(ApiEndpoints.mobilityTrackingStop);
}

final mobilityRemoteProvider = Provider<MobilityRemoteDataSource>(
  (ref) => MobilityRemoteDataSource(ref.watch(apiServiceProvider)),
);
