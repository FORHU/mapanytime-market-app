import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A single destination in [AnimatedBottomNavigation].
class NavBarItem {
  const NavBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Premium floating glass bottom navigation with a smooth animated active
/// pill. Dark-only, uses the design tokens.
class AnimatedBottomNavigation extends StatelessWidget {
  const AnimatedBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.ui.surfaceDark.withValues(alpha: 0.92),
            borderRadius: AppRadius.brPill,
            border: Border.all(color: AppColors.ui.borderDark),
            boxShadow: AppEffects.cardShadow,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.brand.primary;
    final muted = AppColors.text.tertiaryDark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: AppRadius.brPill,
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: selected ? primary : muted,
            ),
          ),
          const Gap(4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : muted,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
