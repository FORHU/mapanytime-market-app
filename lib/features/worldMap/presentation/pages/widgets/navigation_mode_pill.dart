import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/worldMap/data/datasources/directions_datasource.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
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
        color: AppColors.ui.surface,
        borderRadius: AppRadius.brPill,
        boxShadow: AppEffects.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Destination label
          const Icon(Icons.navigation_rounded, size: 16, color: AppColors.ink),
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
                color: AppColors.text.primary,
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          Container(width: 1, height: 24, color: AppColors.ui.borderHairline),
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
          Container(width: 1, height: 24, color: AppColors.ui.borderHairline),
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
                color: AppColors.text.secondary,
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
    final color = selected ? AppColors.ink : AppColors.text.secondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ink.withValues(alpha: 0.1)
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
