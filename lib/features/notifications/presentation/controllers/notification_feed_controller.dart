import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_providers.dart';

/// The session's accumulated notifications plus how many are unread. History is
/// in-memory only — the backend doesn't persist notifications yet, so this
/// resets on app restart.
class NotificationFeedState {
  const NotificationFeedState({this.items = const [], this.unreadCount = 0});

  final List<AppNotification> items;
  final int unreadCount;

  NotificationFeedState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
  }) {
    return NotificationFeedState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Accumulates incoming realtime notifications (newest first) and tracks the
/// unread count for the home bell badge. Subscribes to
/// [incomingNotificationProvider] for its whole lifetime.
class NotificationFeedController extends Notifier<NotificationFeedState> {
  @override
  NotificationFeedState build() {
    ref.listen(incomingNotificationProvider, (_, next) {
      final notification = next.value;
      if (notification != null) _add(notification);
    });
    return const NotificationFeedState();
  }

  void _add(AppNotification notification) {
    // Guard against a rare duplicate delivery of the same event.
    if (state.items.any((n) => n.id == notification.id)) return;
    state = state.copyWith(
      items: [notification, ...state.items],
      unreadCount: state.unreadCount + 1,
    );
  }

  /// Called when the feed screen opens.
  void markAllRead() {
    if (state.unreadCount == 0) return;
    state = state.copyWith(unreadCount: 0);
  }

  void clear() => state = const NotificationFeedState();
}

final notificationFeedControllerProvider =
    NotifierProvider<NotificationFeedController, NotificationFeedState>(
      NotificationFeedController.new,
    );
