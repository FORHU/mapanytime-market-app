import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/mobility/data/mobility_remote_datasource.dart';
import 'package:permission_handler/permission_handler.dart';

/// The signed-in user's assigned vehicle; null for everyone who isn't a
/// driver, which hides driver mode entirely.
final myVehicleProvider = FutureProvider<DriverVehicle?>((ref) async {
  if (!ref.watch(authControllerProvider).isAuthenticated) return null;
  try {
    return await ref.read(mobilityRemoteProvider).myVehicle();
  } on Exception {
    return null;
  }
});

/// While moving, at most one fix per this long.
const minSendGap = Duration(seconds: 10);

/// Longest silence before the last fix is re-sent. Well inside the server's
/// 60s TTL, with room for one lost request.
const heartbeatGap = Duration(seconds: 30);

/// Fixes vaguer than this are noise at street scale (the API rejects >100 m).
const maxFixAccuracyM = 50.0;

/// Below this (m/s, ~5 km/h) a fix counts as parked.
const parkedSpeedMps = 1.5;

/// Whether a fresh GPS fix is worth a request. Moving: one per [minSendGap].
/// Parked: none — the first parked fix reports the stop, and the heartbeat
/// alone keeps the vehicle on the map, cutting a waiting jeepney from 6
/// requests a minute to 2.
@visibleForTesting
bool shouldSendFix({
  required Position fix,
  required Position? lastSent,
  required DateTime lastSentAt,
  required DateTime now,
}) {
  if (fix.accuracy > maxFixAccuracyM) return false;
  if (now.difference(lastSentAt) < minSendGap) return false;
  return lastSent == null || !_isParked(fix) || !_isParked(lastSent);
}

/// Whether nothing has gone out for [heartbeatGap].
@visibleForTesting
bool heartbeatDue({required DateTime lastSentAt, required DateTime now}) =>
    now.difference(lastSentAt) >= heartbeatGap;

// Geolocator reports -1 for "unknown speed"; that isn't evidence of parking.
bool _isParked(Position p) => p.speed >= 0 && p.speed < parkedSpeedMps;

/// Whether this phone is currently broadcasting its driver's vehicle.
///
/// The driver's phone *is* the vehicle's GPS: a position stream posts fixes
/// (see [shouldSendFix]), and a heartbeat re-posts the last good one so a
/// parked vehicle doesn't time out of God's Eye. On Android the stream runs
/// in a foreground service (persistent notification), so it keeps going with
/// the screen off.
class DriverTrackingController extends Notifier<bool> {
  /// How often to check [heartbeatDue]; bounds a heartbeat's lateness.
  static const _heartbeatCheck = Duration(seconds: 5);

  StreamSubscription<Position>? _positions;
  Timer? _heartbeatTimer;

  /// The latest fix accurate enough to send — what the heartbeat re-sends.
  Position? _last;
  Position? _lastSent;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool build() {
    ref.onDispose(_cancel);
    return false;
  }

  /// Starts sharing. Returns an error message for the UI, or null on success.
  Future<String?> start() async {
    if (state) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'Location permission is needed to share your vehicle.';
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Turn on location services to share your vehicle.';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+: without it the foreground-service notification is
      // hidden, and the OS is quicker to kill tracking. Sharing works either
      // way, so a refusal isn't an error.
      await Permission.notification.request();
    }

    _positions = Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).listen(_onPosition, onError: (Object e) => debugPrint('GPS error: $e'));
    _heartbeatTimer = Timer.periodic(_heartbeatCheck, (_) {
      final last = _last;
      if (last == null) return;
      final now = DateTime.now();
      if (heartbeatDue(lastSentAt: _lastSentAt, now: now)) {
        unawaited(_send(last, at: now));
      }
    });
    state = true;
    return null;
  }

  Future<void> stop() async {
    if (!state) return;
    _cancel();
    state = false;
    try {
      await ref.read(mobilityRemoteProvider).stopTracking();
    } on Exception catch (e) {
      // The server drops it after 60s of silence anyway.
      debugPrint('Stop tracking failed: $e');
    }
  }

  void _onPosition(Position p) {
    if (p.accuracy <= maxFixAccuracyM) _last = p;
    // iOS has no interval setting — distanceFilter alone can fire every
    // second at speed, so the send gap is enforced here too.
    final send = shouldSendFix(
      fix: p,
      lastSent: _lastSent,
      lastSentAt: _lastSentAt,
      now: DateTime.now(),
    );
    if (send) unawaited(_send(p));
  }

  Future<void> _send(Position p, {DateTime? at}) async {
    _lastSent = p;
    _lastSentAt = DateTime.now();
    try {
      await ref.read(mobilityRemoteProvider).sendLocation(p, at: at);
    } on UnauthorizedException {
      // 403: vehicle unassigned or suspended mid-shift — stop broadcasting.
      _cancel();
      state = false;
    } on Exception catch (e) {
      // Offline or a rejected fix (422): the next ping tries again.
      debugPrint('Location ping failed: $e');
    }
  }

  void _cancel() {
    unawaited(_positions?.cancel());
    _positions = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    // A restarted shift must not heartbeat where the last one ended.
    _last = null;
    _lastSent = null;
  }

  /// Battery: `high` rather than the plugin's default `best` (street-level
  /// precision without keeping the GPS at full power), a 25 m distance filter
  /// (a vehicle at 20 km/h still covers ~55 m per interval), and an Android
  /// interval matching [minSendGap] so the GPS never wakes for fixes we'd drop.
  static LocationSettings _settings() {
    const distance = 25;
    const accuracy = LocationAccuracy.high;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distance,
        intervalDuration: minSendGap,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Sharing your vehicle location',
          notificationText: 'Your vehicle is visible on the MapAnytime map.',
          enableWakeLock: true,
        ),
      ),
      // Background updates (and not auto-pausing) are the plugin defaults;
      // they also need UIBackgroundModes=location in Info.plist. Keep
      // auto-pausing off: a paused stream only resumes with region
      // monitoring, which this app doesn't do.
      TargetPlatform.iOS => AppleSettings(
        accuracy: accuracy,
        distanceFilter: distance,
        activityType: ActivityType.automotiveNavigation,
        showBackgroundLocationIndicator: true,
      ),
      _ => const LocationSettings(accuracy: accuracy, distanceFilter: distance),
    };
  }
}

final driverTrackingProvider = NotifierProvider<DriverTrackingController, bool>(
  DriverTrackingController.new,
);
