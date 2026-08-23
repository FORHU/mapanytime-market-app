import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_providers.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>(
      (ref) => NotificationRemoteDataSource(ref.watch(apiServiceProvider)),
    );

/// The notification feed: persisted history (`GET /notifications`, fetched
/// once on build) plus anything pushed live over the socket since. History
/// loads in the background — `build()` returns synchronously with an empty
/// list so the socket listener and the two other sync consumers
/// (`home_page.dart`'s bell badge, `notification_toast_host.dart`) don't need
/// an `AsyncNotifier` refactor; [isLoadingHistory] tells the feed page when
/// to show a spinner.
class NotificationFeedState {
  const NotificationFeedState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoadingHistory = true,
  });

  final List<AppNotification> items;
  final int unreadCount;

  /// True until the initial `GET /notifications` + unread-count fetch
  /// completes (or fails). The feed page uses this for its loading state.
  final bool isLoadingHistory;

  NotificationFeedState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoadingHistory,
  }) {
    return NotificationFeedState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
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
    // Fire-and-forget: `build()` must stay sync (two other providers watch
    // this state synchronously), so history arrives via a later `state =`
    // write rather than being awaited here.
    unawaited(_loadHistory());
    return const NotificationFeedState();
  }

  Future<void> _loadHistory() async {
    final source = ref.read(notificationRemoteDataSourceProvider);
    try {
      // FIXME: Future.wait fails fast (eagerError:true default) — a transient
      // error on either request discards the other's already-fetched result.
      // Consider eagerError:false or fetching independently.
      final results = await Future.wait([
        source.getNotifications(),
        source.getUnreadCount(),
      ]);
      final history = results[0] as List<AppNotification>;
      final unreadCount = results[1] as int;

      // Merge with anything the socket already delivered before this
      // resolved, newest first, deduped by id (history wins on conflict —
      // it carries `readAt`, the live push doesn't).
      final byId = {for (final n in history) n.id: n};
      for (final n in state.items) {
        byId.putIfAbsent(n.id, () => n);
      }
      final merged = byId.values.toList()
        ..sort((a, b) {
          final aTime = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      // Do NOT add `state.unreadCount` here. `sendNotification` writes the
      // DB row before emitting the socket event (notification.service.ts),
      // so anything `_add` already counted locally is — by that ordering
      // guarantee — already reflected in this fresh server count. Adding
      // both double-counts every notification that arrived over the socket
      // before this fetch resolved (a common case: opening the app right
      // as one arrives). Anything the socket delivers *after* this point
      // still increments correctly via `_add`'s normal path.
      // FIXME: this ordering guarantee is per-notification (its own write vs
      // its own emit) and doesn't cover a race between this independent GET
      // and a concurrent write+emit for a *different* notification — the
      // fetched count can still land stale and undercount the badge by 1.
      state = state.copyWith(
        items: merged,
        unreadCount: unreadCount,
        isLoadingHistory: false,
      );
    } on Exception {
      // Keep whatever the socket has delivered so far; just stop spinning.
      state = state.copyWith(isLoadingHistory: false);
    }
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
    if (state.unreadCount > 0) {
      state = state.copyWith(unreadCount: 0);
    }
    // Fire-and-forget — the badge already cleared locally; this just
    // persists it server-side so it doesn't come back next cold start.
    // FIXME: fires unconditionally now (no early return when unreadCount was
    // already 0), so a redundant PATCH goes out on every feed screen open.
    unawaited(
      ref.read(notificationRemoteDataSourceProvider).markAllAsRead(),
    );
  }

  void clear() => state = const NotificationFeedState(isLoadingHistory: false);
}

final notificationFeedControllerProvider =
    NotifierProvider<NotificationFeedController, NotificationFeedState>(
      NotificationFeedController.new,
    );
