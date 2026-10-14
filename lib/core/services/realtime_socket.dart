import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// The server events the app listens for. Registered once on the one
/// connection; features read them through [RealtimeSocket.on].
const realtimeEvents = <String>[
  'store:upserted',
  'store:removed',
  'vehicle:moved',
  'vehicle:removed',
  'notification:new',
  'notifications:unauthorized',
];

/// The app's single Socket.IO connection.
///
/// Map stores, God's Eye vehicles and the user's order notifications used to
/// open a connection each — two transports, two handshakes, two heartbeats per
/// phone. They now share this one. It also holds what each feature subscribed
/// to, because the server forgets rooms on a reconnect (and with several API
/// replicas the new connection may land on one that never saw this socket):
/// every (re)connect re-sends the last viewport and, with a freshly read token,
/// the notification subscription.
class RealtimeSocket {
  RealtimeSocket(this._url);

  final String _url;
  io.Socket? _socket;
  bool _connectedBefore = false;

  Map<String, double>? _viewport;
  Future<String?> Function()? _readToken;

  final Map<String, StreamController<dynamic>> _events = {
    for (final e in realtimeEvents) e: StreamController<dynamic>.broadcast(),
  };
  final _reconnected = StreamController<void>.broadcast();

  /// Payloads of [event], which must be one of [realtimeEvents].
  Stream<dynamic> on(String event) {
    final controller = _events[event];
    if (controller == null) {
      throw ArgumentError.value(event, 'event', 'not in realtimeEvents');
    }
    return controller.stream;
  }

  /// Fires after the connection comes back from a drop. Whatever was pushed
  /// while it was down was missed, so listeners should resync.
  Stream<void> get onReconnected => _reconnected.stream;

  /// Opens the connection. Idempotent — every feature calls it.
  void connect() {
    if (_socket != null) return;

    final socket =
        io.io(
          _url,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .enableReconnection()
              // Connected explicitly below, once the handlers are attached.
              .disableAutoConnect()
              .build(),
        )..onConnect((_) {
          unawaited(_resubscribe());
          if (_connectedBefore) _reconnected.add(null);
          _connectedBefore = true;
        });
    for (final entry in _events.entries) {
      socket.on(entry.key, (data) {
        if (!entry.value.isClosed) entry.value.add(data);
      });
    }
    _socket = socket..connect();
  }

  Future<void> _resubscribe() async {
    final viewport = _viewport;
    if (viewport != null) _socket?.emit('subscribe', viewport);
    await _emitNotificationSubscribe();
  }

  /// Streams store and vehicle updates for this region. Safe to call whenever
  /// the viewport changes; replaces the previous region.
  void subscribeViewport(Map<String, double> viewport) {
    _viewport = viewport;
    _socket?.emit('subscribe', viewport);
  }

  /// Joins the signed-in user's notification channel. The server picks the
  /// channel from the token, never from a user id (API F107).
  Future<void> subscribeNotifications(
    Future<String?> Function() readToken,
  ) async {
    _readToken = readToken;
    await _emitNotificationSubscribe();
  }

  Future<void> _emitNotificationSubscribe() async {
    final readToken = _readToken;
    final socket = _socket;
    if (readToken == null || socket == null || !socket.connected) return;
    final token = await readToken();
    if (token == null || token.isEmpty) return;
    // Signed out while the token was being read.
    if (!identical(_readToken, readToken)) return;
    socket.emit('subscribe_notifications', {'token': token});
  }

  /// Leaves the notification channel, e.g. on sign-out. The server has no
  /// unsubscribe event, so the connection is cycled: a new connection holds
  /// no rooms, and the viewport is re-sent on connect.
  void unsubscribeNotifications() {
    if (_readToken == null) return;
    _readToken = null;
    final socket = _socket;
    if (socket == null) return;
    socket
      ..disconnect()
      ..connect();
  }

  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
    for (final c in _events.values) {
      await c.close();
    }
    await _reconnected.close();
  }
}

/// App-wide; lives as long as the app.
final realtimeSocketProvider = Provider<RealtimeSocket>((ref) {
  final socket = RealtimeSocket(AppConfig.instance.socketUrl);
  ref.onDispose(socket.dispose);
  return socket;
});
