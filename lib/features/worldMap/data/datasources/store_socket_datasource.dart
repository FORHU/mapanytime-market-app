import 'dart:async';

import 'package:mapanytime_market_app/core/services/realtime_socket.dart';
import 'package:mapanytime_market_app/features/worldMap/data/models/store_model.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Realtime store updates for the map, over the app's shared
/// [RealtimeSocket]. Subscribes to the current map viewport (so the server only
/// pushes updates for that region) and exposes upsert/remove streams the
/// controller merges into the map. Inactive (unapproved) stores are surfaced
/// as removals so they never appear as markers.
///
/// Vehicles ride the same viewport subscription; the mobility feature reads
/// them from [RealtimeSocket] directly.
class StoreSocketDataSource {
  StoreSocketDataSource(this._socket);

  final RealtimeSocket _socket;

  /// Stores created/updated (and active) within a subscribed region.
  Stream<StoreEntity> get onUpserted => _socket
      .on('store:upserted')
      .where((data) => data is Map && _isActive(data))
      .map(
        (data) => StoreModel.fromJson((data as Map).cast<String, dynamic>()),
      );

  /// Ids of stores removed (or deactivated) within a subscribed region. Only
  /// active stores render, so an inactive/unapproved upsert counts as a removal.
  Stream<String> get onRemoved => Stream<String>.multi((controller) {
    void addId(Object? data) {
      if (data is Map && data['id'] is String) {
        controller.add(data['id'] as String);
      }
    }

    final subs = [
      _socket.on('store:removed').listen(addId),
      _socket.on('store:upserted').listen((data) {
        if (data is Map && !_isActive(data)) addId(data);
      }),
    ];
    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
  });

  static bool _isActive(Map<dynamic, dynamic> data) =>
      data['isActive'] as bool? ?? false;

  void connect() => _socket.connect();

  /// Tell the server which region to stream updates for. Safe to call whenever
  /// the viewport changes.
  void subscribe({
    required double north,
    required double south,
    required double east,
    required double west,
  }) {
    _socket.subscribeViewport({
      'north': north,
      'south': south,
      'east': east,
      'west': west,
    });
  }
}
