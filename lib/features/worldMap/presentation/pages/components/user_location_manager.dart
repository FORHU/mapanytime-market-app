import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class UserLocationManager {
  MapboxMap? _mapboxMap;
  Point? _lastKnownLocation;
  StreamSubscription<geo.Position>? _positionStreamSubscription;

  Future<void> initialize(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  Future<void> enableUserLocation({void Function(Point)? onFirstFix}) async {
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      try {
        final hasService = await geo.Geolocator.isLocationServiceEnabled();
        if (!hasService) {
          debugPrint('Location services are disabled.');
          return;
        }

        var hasFiredFirstFix = false;

        // Enable the native Mapbox pulsing location puck
        if (_mapboxMap != null) {
          await _mapboxMap!.location.updateSettings(
            LocationComponentSettings(
              enabled: true,
              pulsingEnabled: true,
              showAccuracyRing: true,
              puckBearingEnabled: true,
            ),
          );
        }

        Future<void> updateLastLocation(geo.Position currentPos) async {
          _lastKnownLocation = Point(
            coordinates: Position(currentPos.longitude, currentPos.latitude),
          );

          if (!hasFiredFirstFix && onFirstFix != null) {
            hasFiredFirstFix = true;
            onFirstFix(_lastKnownLocation!);
          }
        }

        // Fetch once immediately for stationary users / emulators
        try {
          final initialPos = await geo.Geolocator.getCurrentPosition();
          await updateLastLocation(initialPos);
        } on Exception catch (_) {
          // If GPS hangs or times out, try last known position
          final lastPos = await geo.Geolocator.getLastKnownPosition();
          if (lastPos != null) {
            await updateLastLocation(lastPos);
          }
        }

        _positionStreamSubscription =
            geo.Geolocator.getPositionStream(
              locationSettings: const geo.LocationSettings(
                accuracy: geo.LocationAccuracy.high,
                distanceFilter: 2, // Update every 2 metres
              ),
            ).listen((currentPos) async {
              await updateLastLocation(currentPos);
            });
      } on Exception catch (e) {
        debugPrint('Could not fetch location: $e');
      }
    }
  }

  Point? getUserLocation() {
    return _lastKnownLocation;
  }

  Future<void> dispose() async {
    final cancelSub = _positionStreamSubscription?.cancel();
    if (cancelSub != null) await cancelSub;

    try {
      if (_mapboxMap != null) {
        await _mapboxMap!.location.updateSettings(
          LocationComponentSettings(enabled: false),
        );
      }
    } on Exception catch (_) {}

    _mapboxMap = null;
  }
}
