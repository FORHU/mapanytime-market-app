import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/mobility/data/mobility_remote_datasource.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart'
    show storeSocketProvider;

/// A vehicle not heard from in this long leaves the map — covers a driver
/// losing signal, and a vehicle driving out of the cells this phone watches
/// (the server only tells the cell it's in now, never the one it left).
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
    final pruneTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      state = pruneStale(state, DateTime.now());
    });

    ref.onDispose(() {
      unawaited(movedSub.cancel());
      unawaited(removedSub.cancel());
      pruneTimer.cancel();
    });
    return const {};
  }

  /// Merges in the vehicles currently live inside the bounds. Best-effort: the
  /// socket fills the map in within one ping interval anyway.
  Future<void> loadSnapshot({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
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
