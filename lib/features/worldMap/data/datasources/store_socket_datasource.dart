import 'dart:async';

import 'package:mapanytime_market_app/features/worldMap/data/models/store_model.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Realtime store updates over Socket.IO. Connects to the server, subscribes to
/// the current map viewport (so the server only pushes updates for that
/// region), and exposes upsert/remove streams the controller merges into the
/// map. Inactive (unapproved) stores are surfaced as removals so they never
/// appear as markers.
class StoreSocketDataSource {
  StoreSocketDataSource(this._socketUrl);

  final String _socketUrl;
  io.Socket? _socket;

  final _upserted = StreamController<StoreEntity>.broadcast();
  final _removed = StreamController<String>.broadcast();

  /// Stores created/updated (and active) within a subscribed region.
  Stream<StoreEntity> get onUpserted => _upserted.stream;

  /// Ids of stores removed (or deactivated) within a subscribed region.
  Stream<String> get onRemoved => _removed.stream;

  // God's Eye rides the same connection and viewport subscription as stores.
  // Raw maps: parsing belongs to the mobility feature, not this socket.
  final _vehicleMoved = StreamController<Map<String, dynamic>>.broadcast();
  final _vehicleRemoved = StreamController<String>.broadcast();

  /// `vehicle:moved` payloads for vehicles within a subscribed region.
  Stream<Map<String, dynamic>> get onVehicleMoved => _vehicleMoved.stream;

  /// Ids of vehicles that left a subscribed region: stopped sharing, went
  /// silent for 60s, or drove into a cell outside it.
  Stream<String> get onVehicleRemoved => _vehicleRemoved.stream;

  final _reconnected = StreamController<void>.broadcast();

  /// Fires after the socket comes back from a drop. Whatever was pushed
  /// while it was down was missed, so listeners should resync.
  Stream<void> get onReconnected => _reconnected.stream;

  /// The last viewport asked for. Rooms don't survive a reconnect — and with
  /// more than one API instance it may land on a server that never saw this
  /// socket — so it's sent again on every connect.
  Map<String, double>? _viewport;
  bool _connectedBefore = false;

  void connect() {
    if (_socket != null) return;

    _socket =
        io.io(
            _socketUrl,
            io.OptionBuilder()
                .setTransports(['websocket'])
                .enableReconnection()
                .build(),
          )
          ..onConnect((_) {
            final viewport = _viewport;
            if (viewport != null) _socket?.emit('subscribe', viewport);
            if (_connectedBefore) _reconnected.add(null);
            _connectedBefore = true;
          })
          ..on('store:upserted', (data) {
            if (data is! Map) return;
            final map = data.cast<String, dynamic>();
            final isActive = map['isActive'] as bool? ?? false;
            final id = map['id'] as String?;

            if (isActive) {
              _upserted.add(StoreModel.fromJson(map));
            } else if (id != null) {
              // Only active stores render, so an inactive/unapproved store is
              // treated as a removal.
              _removed.add(id);
            }
          })
          ..on('store:removed', (data) {
            if (data is Map && data['id'] is String) {
              _removed.add(data['id'] as String);
            }
          })
          ..on('vehicle:moved', (data) {
            if (data is Map && data['id'] is String) {
              _vehicleMoved.add(data.cast<String, dynamic>());
            }
          })
          ..on('vehicle:removed', (data) {
            if (data is Map && data['id'] is String) {
              _vehicleRemoved.add(data['id'] as String);
            }
          })
          ..connect();
  }

  /// Tell the server which region to stream updates for. Safe to call whenever
  /// the viewport changes.
  void subscribe({
    required double north,
    required double south,
    required double east,
    required double west,
  }) {
    final viewport = _viewport = {
      'north': north,
      'south': south,
      'east': east,
      'west': west,
    };
    _socket?.emit('subscribe', viewport);
  }

  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
    await _upserted.close();
    await _removed.close();
    await _vehicleMoved.close();
    await _vehicleRemoved.close();
    await _reconnected.close();
  }
}
