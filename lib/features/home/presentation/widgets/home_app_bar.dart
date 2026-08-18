import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/badged_icon_button.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Home top bar: avatar, a location-led greeting ("Discover near ..."), and
/// the notification bell. Per DESIGN.md, the greeting line carries
/// MapAnytime's real differentiator — the current discovery area — rather
/// than a generic "Welcome, name."
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.name,
    required this.location,
    this.onNotifications,
    this.onProfile,
    this.unreadCount = 0,
    super.key,
  });

  final String name;
  final String location;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        _Avatar(name: name, onTap: onProfile),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover near',
                style: tt.bodySmall?.copyWith(color: AppColors.text.secondary),
              ),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge,
              ),
            ],
          ),
        ),
        const Gap(12),
        BadgedIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotifications,
          badgeCount: unreadCount,
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.text.onInk,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
