import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/features/mobility/presentation/driver_tracking_controller.dart';

void main() {
  final now = DateTime(2026, 9, 25, 12);

  Position fix({double speed = 8, double accuracy = 10}) => Position(
    latitude: 16.4023,
    longitude: 120.596,
    timestamp: now,
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 180,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );

  DateTime ago(int seconds) => now.subtract(Duration(seconds: seconds));

  group('shouldSendFix', () {
    test('sends the first fix', () {
      expect(
        shouldSendFix(
          fix: fix(),
          lastSent: null,
          lastSentAt: DateTime.fromMillisecondsSinceEpoch(0),
          now: now,
        ),
        isTrue,
      );
    });

    test('while moving, sends at most one fix per 10s', () {
      bool at(int secondsSinceLast) => shouldSendFix(
        fix: fix(),
        lastSent: fix(),
        lastSentAt: ago(secondsSinceLast),
        now: now,
      );

      expect(at(4), isFalse);
      expect(at(9), isFalse);
      expect(at(10), isTrue);
    });

    test('drops a fix vaguer than 50 m', () {
      expect(
        shouldSendFix(
          fix: fix(accuracy: 80),
          lastSent: fix(),
          lastSentAt: ago(60),
          now: now,
        ),
        isFalse,
      );
    });

    test('reports the first parked fix, so the map shows the stop', () {
      expect(
        shouldSendFix(
          fix: fix(speed: 0),
          lastSent: fix(),
          lastSentAt: ago(15),
          now: now,
        ),
        isTrue,
      );
    });

    test('stays quiet while parked — the heartbeat covers it', () {
      expect(
        shouldSendFix(
          fix: fix(speed: 0.4),
          lastSent: fix(speed: 0),
          lastSentAt: ago(25),
          now: now,
        ),
        isFalse,
      );
    });

    test('an unknown speed (-1) is not taken as parked', () {
      expect(
        shouldSendFix(
          fix: fix(speed: -1),
          lastSent: fix(speed: -1),
          lastSentAt: ago(15),
          now: now,
        ),
        isTrue,
      );
    });

    test('pulling away from a stop sends again', () {
      expect(
        shouldSendFix(
          fix: fix(speed: 4),
          lastSent: fix(speed: 0),
          lastSentAt: ago(12),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('heartbeatDue', () {
    test('fires after 30s of silence — inside the 60s server TTL', () {
      expect(heartbeatDue(lastSentAt: ago(29), now: now), isFalse);
      expect(heartbeatDue(lastSentAt: ago(30), now: now), isTrue);
      expect(heartbeatGap < const Duration(seconds: 60), isTrue);
    });
  });
}
