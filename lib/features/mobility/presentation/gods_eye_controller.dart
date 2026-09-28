import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/mobility/data/mobility_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart'
    show storeSocketProvider;

/// A vehicle not heard from in this long leaves the map. The server already
/// sends `vehicle:removed` on stop, on 60s of silence and when a vehicle
/// leaves the cells this phone watches; this is the fallback for events
/// missed while the socket was down.
const liveVehicleTtl = Duration(seconds: 60);

/// Drops vehicles older than [liveVehicleTtl]. Returns [vehicles] itself when
/// nothing expired, so callers can skip a no-op state update.
@visibleForTesting
Map<String, LiveVehicle> pruneStale(
  Map<String, LiveVehicle> vehicles,
  DateTime now,
) {
  final cutoff = now.subtract(liveVehicleTtl);
  if (!vehicles.values.any((v) => v.receivedAt.isBefore(cutoff))) {
    return vehicles;
  }
  return {
    for (final e in vehicles.entries)
      if (!e.value.receivedAt.isBefore(cutoff)) e.key: e.value,
  };
}

/// God's Eye: the live vehicles in (or recently in) the map's viewport, by id.
/// Fed by the region-scoped socket the store markers already use, plus a
/// snapshot per viewport so parked vehicles show without waiting for a ping.
class GodsEyeController extends Notifier<Map<String, LiveVehicle>> {
  @override
  Map<String, LiveVehicle> build() {
    final socket = ref.read(storeSocketProvider)..connect();

    final movedSub = socket.onVehicleMoved.listen((json) {
      try {
        final v = LiveVehicle.fromJson(json);
        state = {...state, v.id: v};
      } on Object catch (e) {
        debugPrint('Ignoring malformed vehicle:moved: $e');
      }
    });
    final removedSub = socket.onVehicleRemoved.listen((id) {
      if (state.containsKey(id)) state = {...state}..remove(id);
    });
    // Pings sent while the socket was down were missed: catch up.
    final reconnectedSub = socket.onReconnected.listen((_) {
      final bounds = _bounds;
      if (bounds != null) {
        unawaited(
          loadSnapshot(
            north: bounds.north,
            south: bounds.south,
            east: bounds.east,
            west: bounds.west,
          ),
        );
      }
    });
    final pruneTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      state = pruneStale(state, DateTime.now());
    });

    ref.onDispose(() {
      unawaited(movedSub.cancel());
      unawaited(removedSub.cancel());
      unawaited(reconnectedSub.cancel());
      pruneTimer.cancel();
    });
    return const {};
  }

  ({double north, double south, double east, double west})? _bounds;

  /// Merges in the vehicles currently live inside the bounds. Best-effort: the
  /// socket fills the map in within one ping interval anyway.
  Future<void> loadSnapshot({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    _bounds = (north: north, south: south, east: east, west: west);
    try {
      final live = await ref
          .read(mobilityRemoteProvider)
          .liveVehicles(north: north, south: south, east: east, west: west);
      if (live.isEmpty) return;
      state = {...state, for (final v in live) v.id: v};
    } on Exception catch (e) {
      debugPrint('Live vehicle snapshot failed: $e');
    }
  }
}

final godsEyeControllerProvider =
    NotifierProvider<GodsEyeController, Map<String, LiveVehicle>>(
      GodsEyeController.new,
    );

/// Vehicle types for marker icons. Empty on failure — vehicles still render
/// as dots.
final vehicleTypesProvider = FutureProvider<List<VehicleType>>((ref) async {
  try {
    return await ref.read(mobilityRemoteProvider).vehicleTypes();
  } on Exception {
    return const [];
  }
});
