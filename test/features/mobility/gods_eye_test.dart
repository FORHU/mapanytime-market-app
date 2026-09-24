import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/mobility/data/mobility_remote_datasource.dart';
import 'package:mapanytime_market_app/features/mobility/presentation/gods_eye_controller.dart';

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
