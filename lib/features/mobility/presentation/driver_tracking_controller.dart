import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/mobility/data/mobility_remote_datasource.dart';

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

/// Whether this phone is currently broadcasting its driver's vehicle.
///
/// The driver's phone *is* the vehicle's GPS: a position stream posts each
/// fix, and a heartbeat re-posts the last one so a parked vehicle doesn't
/// time out of God's Eye. On Android the stream runs in a foreground service
/// (persistent notification), so it keeps going with the screen off.
class DriverTrackingController extends Notifier<bool> {
  static const _minSendGap = Duration(seconds: 4);
  static const _heartbeat = Duration(seconds: 20);

  StreamSubscription<Position>? _positions;
  Timer? _heartbeatTimer;
  Position? _last;
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

    _positions = Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).listen(_onPosition, onError: (Object e) => debugPrint('GPS error: $e'));
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) {
      final last = _last;
      if (last != null) unawaited(_send(last, at: DateTime.now()));
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
    _last = p;
    // iOS has no interval setting — distanceFilter alone can fire every
    // second at speed. The API's per-ping cost is a DB lookup; keep it sane.
    if (DateTime.now().difference(_lastSentAt) < _minSendGap) return;
    unawaited(_send(p));
  }

  Future<void> _send(Position p, {DateTime? at}) async {
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
  }

  static LocationSettings _settings() {
    const distance = 10;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        distanceFilter: distance,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Sharing your vehicle location',
          notificationText: 'Your vehicle is visible on the MapAnytime map.',
          enableWakeLock: true,
        ),
      ),
      // Background updates (and not auto-pausing) are the plugin defaults;
      // they also need UIBackgroundModes=location in Info.plist.
      TargetPlatform.iOS => AppleSettings(
        distanceFilter: distance,
        activityType: ActivityType.automotiveNavigation,
        showBackgroundLocationIndicator: true,
      ),
      _ => const LocationSettings(distanceFilter: distance),
    };
  }
}

final driverTrackingProvider = NotifierProvider<DriverTrackingController, bool>(
  DriverTrackingController.new,
);
