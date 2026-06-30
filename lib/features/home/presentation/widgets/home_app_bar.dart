import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Home top bar: greeting + name, current location, notification and avatar.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.greeting,
    required this.name,
    required this.location,
    this.onNotifications,
    this.onProfile,
    super.key,
  });

  final String greeting;
  final String name;
  final String location;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.text.secondaryDark,
                ),
              ),
              const Gap(2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              const Gap(6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.brand.primaryBright,
                  ),
                  const Gap(2),
                  Flexible(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.tertiaryDark,
                      ),
                    ),
                  ),
                  const Gap(2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.text.tertiaryDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.sm),
        _IconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotifications,
          showDot: true,
        ),
        const Gap(AppSpacing.sm),
        _Avatar(name: name, onTap: onProfile),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ui.surfaceDark,
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x1FFFFFFF)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.text.primaryDark),
              if (showDot)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.status.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ui.surfaceDark,
                        width: 1.5,
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
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppEffects.primaryGlow,
        ),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
