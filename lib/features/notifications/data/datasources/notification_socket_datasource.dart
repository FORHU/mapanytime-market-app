import 'dart:async';

import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Realtime user notifications over Socket.IO. Connects to the server, joins
/// the signed-in user's notification channel (`subscribe_notifications`), and
/// exposes a stream of incoming `notification:new` events for the app to toast.
///
/// Separate from the store socket: that one is viewport-scoped and lives with
/// the map; this one is user-scoped and lives for the whole session.
class NotificationSocketDataSource {
  NotificationSocketDataSource(this._socketUrl);

  final String _socketUrl;
  io.Socket? _socket;

  final _notifications = StreamController<AppNotification>.broadcast();

  /// Notifications pushed to the subscribed user.
  Stream<AppNotification> get onNotification => _notifications.stream;

  /// [readToken] is called on every (re)connect rather than once: the server
  /// joins the channel of whoever the access token belongs to, and a reconnect
  /// can come long after a refresh replaced the token held at sign-in.
  void connect({required Future<String?> Function() readToken}) {
    if (_socket != null) return;

    _socket =
        io.io(
            _socketUrl,
            io.OptionBuilder()
                .setTransports(['websocket'])
                .enableReconnection()
                .build(),
          )
          // (Re)subscribe on every (re)connect so the channel survives drops.
          ..onConnect((_) async {
            final token = await readToken();
            if (token == null || token.isEmpty) return;
            _socket?.emit('subscribe_notifications', {'token': token});
          })
          ..on('notification:new', (data) {
            if (data is! Map) return;
            final notification = AppNotification.fromJson(
              data.cast<String, dynamic>(),
            );
            if (notification.id.isNotEmpty) {
              _notifications.add(notification);
            }
          })
          ..connect();
  }

  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
    await _notifications.close();
  }
}
