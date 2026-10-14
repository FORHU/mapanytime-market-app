import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// The map's own view of where the user is: the native location puck plus a
/// Geolocator stream that keeps [getUserLocation] current.
///
/// The stream is the expensive part — high accuracy, every 2 m — so it runs
/// only while the map is actually on screen. [pause] stops it when the app is
/// backgrounded or the map tab is hidden; [resume] restarts it without asking
/// for permission again.
class UserLocationManager {
  MapboxMap? _mapboxMap;
  Point? _lastKnownLocation;
  StreamSubscription<geo.Position>? _positionStreamSubscription;

  /// Set once [enableUserLocation] succeeds; [resume] only restarts what was
  /// running.
  bool _enabled = false;
  bool _paused = false;

  Future<void> initialize(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  /// Called on every style load. A style switch wipes the puck, so it is
  /// re-enabled each time — but the position stream is replaced, not stacked:
  /// each call used to overwrite the subscription without cancelling it, so
  /// every streets/satellite toggle leaked one more 2 m GPS listener.
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

        void updateLastLocation(geo.Position currentPos) {
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
          updateLastLocation(initialPos);
        } on Exception catch (_) {
          // If GPS hangs or times out, try last known position
          final lastPos = await geo.Geolocator.getLastKnownPosition();
          if (lastPos != null) {
            updateLastLocation(lastPos);
          }
        }

        _enabled = true;
        // Paused while this was awaiting (map hidden or app backgrounded):
        // leave the stream off; resume() starts it.
        if (!_paused) await _startStream(updateLastLocation);
      } on Exception catch (e) {
        debugPrint('Could not fetch location: $e');
      }
    }
  }

  Future<void> _startStream(void Function(geo.Position) onPosition) async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 2, // Update every 2 metres
      ),
    ).listen(onPosition);
  }

  /// Stops the GPS stream; the last known location stays readable.
  Future<void> pause() async {
    _paused = true;
    final sub = _positionStreamSubscription;
    _positionStreamSubscription = null;
    await sub?.cancel();
  }

  /// Restarts the GPS stream if it was running before [pause]. Never prompts:
  /// a permission revoked while paused leaves it off.
  Future<void> resume() async {
    _paused = false;
    if (!_enabled || _positionStreamSubscription != null) return;
    if (!await Permission.locationWhenInUse.isGranted) return;
    await _startStream((p) {
      _lastKnownLocation = Point(
        coordinates: Position(p.longitude, p.latitude),
      );
    });
  }

  Point? getUserLocation() {
    return _lastKnownLocation;
  }

  Future<void> dispose() async {
    _enabled = false;
    final cancelSub = _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
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
