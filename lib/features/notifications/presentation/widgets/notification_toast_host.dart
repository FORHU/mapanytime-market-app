import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_feed_controller.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Wraps the whole app (via `MaterialApp.router`'s builder) and shows a
/// floating toast whenever a realtime notification arrives for the user.
///
/// Watching [incomingNotificationProvider] here keeps the notification
/// socket connected for the whole session, regardless of the current route.
class NotificationToastHost extends ConsumerWidget {
  const NotificationToastHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the feed controller alive for the whole session so it accumulates
    // notifications (and drives the bell badge) even before the feed is opened.
    // Watching `.notifier` keeps it active without rebuilding on every event.
    ref
      ..watch(notificationFeedControllerProvider.notifier)
      ..listen<AsyncValue<AppNotification>>(incomingNotificationProvider, (
        _,
        next,
      ) {
        final notification = next.value;
        if (notification != null) {
          _showToast(context, notification);
          final type = notification.metadata?['type'] as String?;
          final isOrderUpdate =
              type == 'ORDER_UPDATED' ||
              type == 'ORDER_CREATED' ||
              type == 'ORDER_PAID';
          if (isOrderUpdate) {
            ref.invalidate(ordersProvider);
          }
        }
      });

    return child;
  }

  void _showToast(BuildContext context, AppNotification notification) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ui.surfaceDark,
          padding: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brMd,
            side: BorderSide(color: AppColors.ui.borderDark),
          ),
          content: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brand.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.brSm,
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: AppColors.brand.primary,
                  size: 20,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const Gap(2),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text.secondaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
