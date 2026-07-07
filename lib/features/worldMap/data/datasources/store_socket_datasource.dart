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
    _socket?.emit('subscribe', {
      'north': north,
      'south': south,
      'east': east,
      'west': west,
    });
  }

  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
    await _upserted.close();
    await _removed.close();
  }
}
