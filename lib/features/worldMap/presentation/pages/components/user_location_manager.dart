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

  Future<void> enableUserLocation() async {
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      try {
        final hasService = await geo.Geolocator.isLocationServiceEnabled();
        if (!hasService) {
          debugPrint('Location services are disabled.');
          return;
        }

        _positionStreamSubscription = geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 2, // Update every 2 meters
          ),
        ).listen((currentPos) async {
          if (_circleAnnotationManager == null) return;

          final pos = Position(currentPos.longitude, currentPos.latitude);

          if (_userLocationAnnotation == null) {
            _userLocationAnnotation = await _circleAnnotationManager!.create(
              CircleAnnotationOptions(
                geometry: Point(coordinates: pos),
                circleColor: Colors.blue.toARGB32(),
                circleRadius: 10,
                circleStrokeColor: Colors.white.toARGB32(),
                circleStrokeWidth: 3,
              ),
            );
          } else {
            _userLocationAnnotation!.geometry = Point(coordinates: pos);
            await _circleAnnotationManager!.update(_userLocationAnnotation!);
          }
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
