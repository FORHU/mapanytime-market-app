import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// A latitude/longitude pair.
typedef LatLng = ({double lat, double lng});

/// Thin wrapper over Geolocator's static API so location consumers can be
/// faked in tests.
class LocationGateway {
  const LocationGateway();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  /// A fresh fix, falling back to the last known position when GPS is slow or
  /// fails. Null when neither is available.
  Future<LatLng?> currentPosition() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } on Exception catch (e) {
      debugPrint('No current position ($e); trying last known.');
    }
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : (lat: p.latitude, lng: p.longitude);
    } on Exception catch (_) {
      // Not supported on web.
      return null;
    }
  }

  /// Emits whenever the device has moved [distanceFilterMeters] or more.
  Stream<LatLng> positionChanges({required int distanceFilterMeters}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: distanceFilterMeters,
        ),
      ).map((p) => (lat: p.latitude, lng: p.longitude));

  /// Straight-line distance in metres.
  double distanceBetween(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng);

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
