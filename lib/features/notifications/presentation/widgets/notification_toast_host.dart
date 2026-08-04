import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/notifications/domain/entities/app_notification.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_feed_controller.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Wraps the whole app (via `MaterialApp.router`'s builder) and shows a
/// small, top-floating compact toast whenever a realtime notification arrives.
class NotificationToastHost extends ConsumerWidget {
  const NotificationToastHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(notificationFeedControllerProvider.notifier)
      ..listen<AsyncValue<AppNotification>>(incomingNotificationProvider, (
        _,
        next,
      ) {
        final notification = next.value;
        if (notification != null) {
          _showTopToast(context, notification);
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

  void _showTopToast(BuildContext context, AppNotification notification) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CompactTopToast(
        notification: notification,
        onDismissed: entry.remove,
      ),
    );
    overlay.insert(entry);
  }
}

class _CompactTopToast extends StatefulWidget {
  const _CompactTopToast({
    required this.notification,
    required this.onDismissed,
  });

  final AppNotification notification;
  final VoidCallback onDismissed;

  @override
  State<_CompactTopToast> createState() => _CompactTopToastState();
}

class _CompactTopToastState extends State<_CompactTopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.5),
    end: Offset.zero,
  ).animate(_fade);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward());
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    unawaited(_reverseAndRemove());
  }

  Future<void> _reverseAndRemove() async {
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.notification.body.isNotEmpty
        ? '${widget.notification.title}: ${widget.notification.body}'
        : widget.notification.title;

    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Align(
                alignment: Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ui.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.brand.primary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.brand.primary.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              color: AppColors.brand.primary,
                              size: 13,
                            ),
                          ),
                          const Gap(8),
                          Flexible(
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.text.primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
