import 'dart:async';

import 'package:mapanytime_market_app/core/services/realtime_socket.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';

/// Realtime user notifications over the app's shared [RealtimeSocket]: joins
/// the signed-in user's notification channel and exposes incoming
/// `notification:new` events for the app to toast.
///
/// Scoped to the signed-in user — [dispose] leaves the channel but keeps the
/// shared connection, which the map is still using.
class NotificationSocketDataSource {
  NotificationSocketDataSource(this._socket);

  final RealtimeSocket _socket;

  /// Notifications pushed to the subscribed user.
  Stream<AppNotification> get onNotification => _socket
      .on('notification:new')
      .where((data) => data is Map)
      .map(
        (data) =>
            AppNotification.fromJson((data as Map).cast<String, dynamic>()),
      )
      .where((notification) => notification.id.isNotEmpty);

  /// [readToken] is called on every (re)connect rather than once: the server
  /// joins the channel of whoever the access token belongs to, and a reconnect
  /// can come long after a refresh replaced the token held at sign-in.
  void connect({required Future<String?> Function() readToken}) {
    _socket.connect();
    unawaited(_socket.subscribeNotifications(readToken));
  }

  Future<void> dispose() async => _socket.unsubscribeNotifications();
}
