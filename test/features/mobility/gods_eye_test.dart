import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/mobility/data/mobility_remote_datasource.dart';
import 'package:mapanytime_market_app/features/mobility/presentation/gods_eye_controller.dart';
import 'package:mapanytime_market_app/features/mobility/presentation/vehicle_layer.dart';

void main() {
  final now = DateTime(2026, 9, 24, 12);

  LiveVehicle heardAt(String id, DateTime at) => LiveVehicle.fromJson({
    'id': id,
    'plateNumber': 'JEEP-001',
    'typeCode': 'JEEPNEY',
    'lat': 16.4023,
    'lng': 120.596,
  }, now: at);

  test('parses the vehicle:moved payload the API emits', () {
    final v = LiveVehicle.fromJson({
      'id': 'v1',
      'plateNumber': 'JEEP-001',
      'typeCode': 'JEEPNEY',
      'lat': 16.4023,
      'lng': 120, // ints arrive for whole-degree coordinates
      'heading': 182,
      'speed': 23,
      'ts': 1790221957998,
    }, now: now);

    expect(v.lng, 120.0);
    expect(v.heading, 182.0);
    expect(v.receivedAt, now);
    // Payloads from before status/accuracy existed still parse.
    expect(v.isStopped, isFalse);
    expect(v.accuracy, isNull);
  });

  test('parses status and accuracy', () {
    final v = LiveVehicle.fromJson({
      'id': 'v1',
      'lat': 16.4,
      'lng': 120.6,
      'accuracy': 12,
      'status': 'stopped',
      'stoppedSince': 1790221957998,
    }, now: now);

    expect(v.isStopped, isTrue);
    expect(v.accuracy, 12.0);
  });

  group('VehicleLayer.glideFrame', () {
    LiveVehicle at(String id, double lat, double lng) => LiveVehicle.fromJson(
      {'id': id, 'lat': lat, 'lng': lng},
      now: now,
    );

    test('moves a vehicle part of the way from where it was drawn', () {
      final frame = VehicleLayer.glideFrame(
        [at('a', 16.401, 120.6)],
        {'a': (lat: 16.4, lng: 120.6)},
        0.5,
      );

      expect(frame.single.$2, closeTo(16.4005, 1e-9));
      expect(frame.single.$3, 120.6);
    });

    test('snaps new vehicles and long jumps', () {
      final frame = VehicleLayer.glideFrame(
        [at('new', 16.4, 120.6), at('far', 17, 120.6)],
        {'far': (lat: 16.4, lng: 120.6)},
        0.2,
      );

      expect([for (final f in frame) f.$2], [16.4, 17.0]);
    });
  });

  test('drops only vehicles not heard from within the TTL', () {
    final vehicles = {
      'fresh': heardAt('fresh', now.subtract(const Duration(seconds: 59))),
      'ghost': heardAt('ghost', now.subtract(const Duration(seconds: 61))),
    };

    expect(pruneStale(vehicles, now).keys, ['fresh']);
  });

  test('returns the same map when nothing expired (no needless rebuild)', () {
    final vehicles = {'a': heardAt('a', now)};

    expect(identical(pruneStale(vehicles, now), vehicles), isTrue);
  });
}
