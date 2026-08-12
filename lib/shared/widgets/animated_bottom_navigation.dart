import 'package:flutter/material.dart';
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
    this.showBadge = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Shows a small notification dot on the icon (e.g. unseen cart items).
  final bool showBadge;
}

/// Floating glass pill bottom nav — icon-only, white scheme.
/// Shrinks subtly when [isCompact] (user scrolling down).
class AnimatedBottomNavigation extends StatelessWidget {
  const AnimatedBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.isCompact = false,
    super.key,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          scale: isCompact ? 0.85 : 1.0,
          child: Container(
            height: 72,
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

  static const _activeColor = Colors.white;
  static const _inactiveColor = Color(0x66FFFFFF); // white 40%

  @override
  Widget build(BuildContext context) {
    final color = selected ? _activeColor : _inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
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
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: AppRadius.brPill,
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: 28,
                color: color,
              ),
            ),
            if (item.showBadge)
              Positioned(
                right: 6,
                top: 0,
                child: Container(
                  width: 9,
                  height: 9,
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
    );
  }
}
