import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_feed_controller.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// The notification feed opened from the home bell. Lists notifications
/// received this session (newest first) and clears the unread badge on open.
class NotificationFeedPage extends ConsumerStatefulWidget {
  const NotificationFeedPage({super.key});

  @override
  ConsumerState<NotificationFeedPage> createState() =>
      _NotificationFeedPageState();
}

class _NotificationFeedPageState extends ConsumerState<NotificationFeedPage> {
  @override
  void initState() {
    super.initState();
    // Clear the unread count once the feed is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationFeedControllerProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(
      notificationFeedControllerProvider.select((s) => s.items),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const _EmptyFeed()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
              itemBuilder: (context, i) => _NotificationTile(items[i]),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.notification);

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceDark,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.ui.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: AppColors.text.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (notification.sentAt != null) ...[
                      const Gap(AppSpacing.sm),
                      Text(
                        _relativeTime(notification.sentAt!),
                        style: TextStyle(
                          color: AppColors.text.tertiaryDark,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if (notification.body.isNotEmpty) ...[
                  const Gap(4),
                  Text(
                    notification.body,
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
    );
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 44,
            color: AppColors.text.tertiaryDark,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'No notifications yet',
            style: TextStyle(color: AppColors.text.secondaryDark),
          ),
        ],
      ),
    );
  }
}
