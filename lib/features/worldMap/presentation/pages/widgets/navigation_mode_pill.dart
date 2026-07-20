import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/directions_datasource.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Floating pill shown on the map while a navigation route is active.
/// Lets the user switch travel modes and cancel navigation.
class NavigationModePill extends StatelessWidget {
  const NavigationModePill({
    required this.selectedMode,
    required this.storeName,
    required this.onModeChanged,
    required this.onCancel,
    super.key,
  });

  final TravelMode selectedMode;
  final String storeName;
  final ValueChanged<TravelMode> onModeChanged;
  final VoidCallback onCancel;

  static const _modes = <(TravelMode, IconData, String)>[
    (TravelMode.driving, Icons.directions_car_rounded, 'Car'),
    (TravelMode.walking, Icons.directions_walk_rounded, 'Walk'),
    (TravelMode.cycling, Icons.directions_bike_rounded, 'Bike'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceDark,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.ui.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Destination label
          Icon(
            Icons.navigation_rounded,
            size: 16,
            color: AppColors.brand.primary,
          ),
          const Gap(AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text.primaryDark,
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          Container(width: 1, height: 24, color: AppColors.ui.borderDark),
          const Gap(AppSpacing.sm),
          // Mode buttons
          for (final (mode, icon, label) in _modes) ...[
            _ModeButton(
              icon: icon,
              label: label,
              selected: selectedMode == mode,
              onTap: () => onModeChanged(mode),
            ),
            if (mode != TravelMode.cycling) const Gap(AppSpacing.xs),
          ],
          const Gap(AppSpacing.sm),
          Container(width: 1, height: 24, color: AppColors.ui.borderDark),
          const Gap(AppSpacing.xs),
          // Cancel button
          GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.text.secondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.brand.primary : AppColors.text.secondaryDark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
