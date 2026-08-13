import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Home top bar: avatar, greeting + name, notification, and location selector.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.greeting,
    required this.name,
    required this.location,
    this.onNotifications,
    this.onProfile,
    this.unreadCount = 0,
    super.key,
  });

  final String greeting;
  final String name;
  final String location;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Avatar(name: name, onTap: onProfile),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.text.secondaryDark,
                    ),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleLarge,
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.sm),
            _NotificationButton(
              onTap: onNotifications,
              badgeCount: unreadCount,
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        _LocationSelector(location: location),
      ],
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceElevatedDark,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.ui.borderDark),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 16,
            color: AppColors.brand.primaryBright,
          ),
          const Gap(AppSpacing.xs),
          Expanded(
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: AppColors.text.secondaryDark,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.text.tertiaryDark,
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({this.onTap, this.badgeCount = 0});

  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ui.surfaceDark,
      shape: const CircleBorder(side: BorderSide(color: Color(0x1FFFFFFF))),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: AppColors.text.primaryDark,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.status.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.ui.surfaceDark,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
        decoration: BoxDecoration(
          color: AppColors.ui.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.brand.primary, width: 1.5),
        ),
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.brand.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
