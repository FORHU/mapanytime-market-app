import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';

/// The persisted notification feed (`GET /notifications`) — the socket only
/// covers what's pushed while the app is open; this is what backfills
/// history on cold start.
class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._api);

  final ApiService _api;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _api.get(ApiEndpoints.notifications);
    final rawList = response is Map && response['data'] is List
        ? response['data'] as List
        : const <dynamic>[];

    return rawList
        .map(
          (e) => AppNotification.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> markAllAsRead() =>
      _api.patch(ApiEndpoints.notificationsMarkAllRead);

  Future<int> getUnreadCount() async {
    final response = await _api.get(ApiEndpoints.notificationsUnreadCount);
    final data = response is Map ? response['data'] : null;
    return data is Map ? (data['count'] as num?)?.toInt() ?? 0 : 0;
  }
}
