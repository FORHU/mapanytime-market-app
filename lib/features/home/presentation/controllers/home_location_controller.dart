import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/features/home/data/datasources/location_gateway.dart';
import 'package:mapanytime_market_app/features/home/data/datasources/reverse_geocoding_datasource.dart';

final locationGatewayProvider = Provider<LocationGateway>(
  (ref) => const LocationGateway(),
);

final reverseGeocodingDatasourceProvider = Provider<ReverseGeocodingDatasource>(
  (ref) => ReverseGeocodingDatasource(),
);

enum HomeLocationStatus {
  locating,
  located,

  /// Permission denied, but the OS will still show the prompt again.
  permissionDenied,

  /// Permission permanently denied — only the app settings page can fix it.
  permissionDeniedForever,

  /// Device location (GPS) is switched off.
  serviceDisabled,

  /// Permission granted but no fix, or the fix couldn't be named.
  unavailable,
}

class HomeLocationState {
  const HomeLocationState(this.status, {this.label});

  final HomeLocationStatus status;

  /// Place name ("Baguio, Benguet"); set only when [status] is located.
  final String? label;
}

/// The Home header's "Discover near ..." area: asks for permission, reads the
/// device position, reverse-geocodes it to a city, and follows the user as
/// they move between cities.
class HomeLocationController extends Notifier<HomeLocationState> {
  /// Movement that triggers a new lookup — city scale, so Mapbox is only hit
  /// after a meaningful move.
  static const moveThresholdMeters = 1000;

  StreamSubscription<LatLng>? _moves;
  LatLng? _lastGeocoded;

  /// Bumped on every (re)start so a superseded run drops its results.
  int _run = 0;

  @override
  HomeLocationState build() {
    ref.onDispose(() => _moves?.cancel());
    unawaited(_start(request: true));
    return const HomeLocationState(HomeLocationStatus.locating);
  }

  LocationGateway get _gateway => ref.read(locationGatewayProvider);

  /// Re-checks service + permission and re-locates. Never shows the
  /// permission prompt: on Android, dismissing that prompt itself fires an
  /// app resume, and prompting from there would loop.
  Future<void> refresh() => _start(request: false);

  /// What tapping the header does when the location isn't available: ask
  /// again, or send the user to the settings page that can fix it. Returning
  /// to the app triggers [refresh] (see HomePage).
  Future<void> resolve() async {
    switch (state.status) {
      case HomeLocationStatus.permissionDeniedForever:
        await _gateway.openAppSettings();
      case HomeLocationStatus.serviceDisabled:
        await _gateway.openLocationSettings();
      case HomeLocationStatus.permissionDenied:
      case HomeLocationStatus.unavailable:
        await _start(request: true);
      case HomeLocationStatus.locating:
      case HomeLocationStatus.located:
        break;
    }
  }

  Future<void> _start({required bool request}) async {
    final run = ++_run;
    await _moves?.cancel();
    _moves = null;
    _lastGeocoded = null;
    // Keep showing the current city while re-checking (pull-to-refresh).
    if (state.status != HomeLocationStatus.located) {
      _set(run, const HomeLocationState(HomeLocationStatus.locating));
    }

    if (!await _gateway.isServiceEnabled()) {
      return _set(
        run,
        const HomeLocationState(HomeLocationStatus.serviceDisabled),
      );
    }

    var permission = await _gateway.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await _gateway.requestPermission();
    }
    if (!_isCurrent(run)) return;
    switch (permission) {
      case LocationPermission.deniedForever:
        return _set(
          run,
          const HomeLocationState(HomeLocationStatus.permissionDeniedForever),
        );
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return _set(
          run,
          const HomeLocationState(HomeLocationStatus.permissionDenied),
        );
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
    }

    final position = await _gateway.currentPosition();
    if (!_isCurrent(run)) return;
    if (position != null) await _locate(run, position);
    if (!_isCurrent(run)) return;
    if (state.status != HomeLocationStatus.located) {
      _set(run, const HomeLocationState(HomeLocationStatus.unavailable));
    }

    // Follow the user; also recovers if the first fix was missing.
    _moves = _gateway
        .positionChanges(distanceFilterMeters: moveThresholdMeters)
        .listen(
          (p) => unawaited(_locate(run, p)),
          onError: (Object _) {}, // Keep the last known city.
        );
  }

  /// Names [position] and shows it. A failed lookup keeps the previous city.
  Future<void> _locate(int run, LatLng position) async {
    final last = _lastGeocoded;
    if (last != null &&
        _gateway.distanceBetween(last, position) < moveThresholdMeters) {
      return;
    }
    final label = await ref
        .read(reverseGeocodingDatasourceProvider)
        .placeName(lat: position.lat, lng: position.lng);
    if (label == null || !_isCurrent(run)) return;
    _lastGeocoded = position;
    if (label != state.label) {
      _set(run, HomeLocationState(HomeLocationStatus.located, label: label));
    }
  }

  bool _isCurrent(int run) => ref.mounted && run == _run;

  void _set(int run, HomeLocationState next) {
    if (_isCurrent(run)) state = next;
  }
}

final homeLocationControllerProvider =
    NotifierProvider<HomeLocationController, HomeLocationState>(
      HomeLocationController.new,
    );
