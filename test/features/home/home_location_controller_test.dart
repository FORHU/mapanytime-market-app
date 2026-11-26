import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/features/home/data/datasources/location_gateway.dart';
import 'package:mapanytime_market_app/features/home/data/datasources/reverse_geocoding_datasource.dart';
import 'package:mapanytime_market_app/features/home/presentation/controllers/home_location_controller.dart';

const LatLng _baguio = (lat: 16.4023, lng: 120.5960);
const LatLng _candon = (lat: 17.1947, lng: 120.4517);

/// Scriptable device: service, permission, first fix, and a movement stream.
/// Inherits the pure-math [LocationGateway.distanceBetween].
class _FakeGateway extends LocationGateway {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;
  LatLng? fix = _baguio;
  final moves = StreamController<LatLng>.broadcast();
  int requests = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return permission = permissionAfterRequest;
  }

  @override
  Future<LatLng?> currentPosition() async => fix;

  @override
  Stream<LatLng> positionChanges({required int distanceFilterMeters}) =>
      moves.stream;

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }
}

class _FakeGeocoder implements ReverseGeocodingDatasource {
  int lookups = 0;

  @override
  Future<String?> placeName({required double lat, required double lng}) async {
    lookups++;
    if (lat == _baguio.lat) return 'Baguio, Benguet';
    if (lat == _candon.lat) return 'Candon, Ilocos Sur';
    return null;
  }
}

void main() {
  late _FakeGateway gateway;
  late _FakeGeocoder geocoder;
  late ProviderContainer container;

  setUp(() {
    gateway = _FakeGateway();
    geocoder = _FakeGeocoder();
    container = ProviderContainer(
      overrides: [
        locationGatewayProvider.overrideWithValue(gateway),
        reverseGeocodingDatasourceProvider.overrideWithValue(geocoder),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await gateway.moves.close();
  });

  /// Lets the controller's async chain run to completion.
  Future<HomeLocationState> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(homeLocationControllerProvider);
  }

  HomeLocationController controller() =>
      container.read(homeLocationControllerProvider.notifier);

  test('shows the reverse-geocoded city for the current position', () async {
    expect(
      container.read(homeLocationControllerProvider).status,
      HomeLocationStatus.locating,
    );
    final state = await settle();
    expect(state.status, HomeLocationStatus.located);
    expect(state.label, 'Baguio, Benguet');
  });

  test('asks for permission once and reports a denial', () async {
    gateway
      ..permission = LocationPermission.denied
      ..permissionAfterRequest = LocationPermission.denied;
    container.read(homeLocationControllerProvider);
    final state = await settle();
    expect(state.status, HomeLocationStatus.permissionDenied);
    expect(gateway.requests, 1);

    // Tapping the header asks again; granting resolves the city.
    gateway.permissionAfterRequest = LocationPermission.whileInUse;
    await controller().resolve();
    expect((await settle()).label, 'Baguio, Benguet');
    expect(gateway.requests, 2);
  });

  test('refresh (app resume) never shows the permission prompt', () async {
    gateway
      ..permission = LocationPermission.denied
      ..permissionAfterRequest = LocationPermission.denied;
    container.read(homeLocationControllerProvider);
    await settle();
    await controller().refresh();
    await settle();
    expect(gateway.requests, 1);
  });

  test('permanent denial sends the user to app settings', () async {
    gateway.permission = LocationPermission.deniedForever;
    container.read(homeLocationControllerProvider);
    expect(
      (await settle()).status,
      HomeLocationStatus.permissionDeniedForever,
    );
    await controller().resolve();
    expect(gateway.appSettingsOpened, 1);
    expect(gateway.requests, 0);

    // Granted in Settings, then the app resumes.
    gateway.permission = LocationPermission.whileInUse;
    await controller().refresh();
    expect((await settle()).label, 'Baguio, Benguet');
  });

  test('GPS switched off sends the user to location settings', () async {
    gateway.serviceEnabled = false;
    container.read(homeLocationControllerProvider);
    expect((await settle()).status, HomeLocationStatus.serviceDisabled);
    await controller().resolve();
    expect(gateway.locationSettingsOpened, 1);
  });

  test('no fix is unavailable until the device reports a position', () async {
    gateway.fix = null;
    container.read(homeLocationControllerProvider);
    expect((await settle()).status, HomeLocationStatus.unavailable);

    gateway.moves.add(_baguio);
    expect((await settle()).label, 'Baguio, Benguet');
  });

  test('follows the user to a new city, ignoring small moves', () async {
    container.read(homeLocationControllerProvider);
    await settle();
    expect(geocoder.lookups, 1);

    // ~100 m away: same city, no new lookup.
    gateway.moves.add((lat: _baguio.lat + 0.001, lng: _baguio.lng));
    await settle();
    expect(geocoder.lookups, 1);

    gateway.moves.add(_candon);
    final state = await settle();
    expect(state.label, 'Candon, Ilocos Sur');
    expect(geocoder.lookups, 2);
  });

  test('a failed lookup keeps the last known city', () async {
    container.read(homeLocationControllerProvider);
    await settle();
    gateway.moves.add((lat: 0, lng: 0)); // geocoder returns null
    final state = await settle();
    expect(state.status, HomeLocationStatus.located);
    expect(state.label, 'Baguio, Benguet');
  });
}
