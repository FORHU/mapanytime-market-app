import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class UserLocationManager {
  CircleAnnotationManager? _circleAnnotationManager;
  CircleAnnotation? _userLocationAnnotation;
  StreamSubscription<geo.Position>? _positionStreamSubscription;

  Future<void> initialize(MapboxMap mapboxMap) async {
    _circleAnnotationManager =
        await mapboxMap.annotations.createCircleAnnotationManager();
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

        bool hasFiredFirstFix = false;

        Future<void> updateDot(geo.Position currentPos) async {
          if (_circleAnnotationManager == null) return;
          final pos = Point(
            coordinates: Position(currentPos.longitude, currentPos.latitude),
          );

          if (_userLocationAnnotation == null) {
            _userLocationAnnotation = await _circleAnnotationManager!.create(
              CircleAnnotationOptions(
                geometry: pos,
                circleColor: Colors.blue.toARGB32(),
                circleRadius: 10,
                circleStrokeColor: Colors.white.toARGB32(),
                circleStrokeWidth: 3,
              ),
            );
          } else {
            _userLocationAnnotation!.geometry = pos;
            await _circleAnnotationManager!.update(_userLocationAnnotation!);
          }

          if (!hasFiredFirstFix && onFirstFix != null) {
            hasFiredFirstFix = true;
            onFirstFix(pos);
          }
        }

        // Fetch once immediately for stationary users / emulators
        try {
          final initialPos = await geo.Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 4));
          await updateDot(initialPos);
        } on Exception catch (_) {
          // If GPS hangs or times out, try last known position
          final lastPos = await geo.Geolocator.getLastKnownPosition();
          if (lastPos != null) {
            await updateDot(lastPos);
          }
        }

        _positionStreamSubscription = geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 2, // Update every 2 metres
          ),
        ).listen((currentPos) async {
          await updateDot(currentPos);
        });
      } on Exception catch (e) {
        debugPrint('Could not fetch location: $e');
      }
    }
  }

  Point? getUserLocation() {
    return _userLocationAnnotation?.geometry;
  }

  Future<void> dispose() async {
    final cancelSub = _positionStreamSubscription?.cancel();
    if (cancelSub != null) await cancelSub;

    final cancelUserGPS = _circleAnnotationManager?.deleteAll();
    if (cancelUserGPS != null) await cancelUserGPS;

    _circleAnnotationManager = null;
    _userLocationAnnotation = null;
  }
}
