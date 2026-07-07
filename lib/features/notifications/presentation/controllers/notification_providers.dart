import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/notifications/data/datasources/notification_socket_datasource.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';

/// Owns the notification socket, scoped to the signed-in user. Null while
/// logged out. Rebuilds (and reconnects) when the authenticated user changes;
/// the old connection is torn down via [Ref.onDispose].
final notificationSocketProvider = Provider<NotificationSocketDataSource?>((
  ref,
) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return null;

  final source = NotificationSocketDataSource(AppConfig.instance.socketUrl)
    ..connect(userId: user.id);
  ref.onDispose(source.dispose);
  return source;
});

/// Stream of notifications for the signed-in user; empty while logged out.
/// Watched by the app-wide toast host so the socket stays connected for the
/// whole session.
final incomingNotificationProvider = StreamProvider<AppNotification>((ref) {
  final source = ref.watch(notificationSocketProvider);
  if (source == null) return const Stream<AppNotification>.empty();
  return source.onNotification;
});
