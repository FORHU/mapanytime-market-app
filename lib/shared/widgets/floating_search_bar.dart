import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/icon_button.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A search pill for the home and list screens — opaque surface-muted
/// fill, no border, no shadow, per DESIGN.md.
///
/// Pass [onTap] to use it as a tappable button (e.g. opens a search screen);
/// otherwise provide a [controller]/[onChanged] for inline editing. Pass
/// [onFilterTap] to show a trailing icon-button — Home wires this to the
/// map entry point rather than a filter sheet (the app has no separate
/// product-filter feature to hang a filter icon on).
class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    this.hint = 'Search stores or products...',
    this.controller,
    this.onChanged,
    this.onTap,
    this.onFilterTap,
    this.filterIcon = Icons.tune_rounded,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final IconData filterIcon;

  @override
  Widget build(BuildContext context) {
    final readOnly = onTap != null;
    final hasFilter = onFilterTap != null;
    final baseStyle = Theme.of(context).textTheme.bodyLarge;

    return Container(
      height: 54,
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: hasFilter ? 6 : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceMuted,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.text.secondary,
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              readOnly: readOnly,
              onTap: onTap,
              style: baseStyle?.copyWith(color: AppColors.text.primary),
              cursorColor: AppColors.ink,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                hintText: hint,
                hintStyle: baseStyle?.copyWith(color: AppColors.text.tertiary),
              ),
            ),
          ),
          if (hasFilter) AppIconButton(icon: filterIcon, onTap: onFilterTap),
        ],
      ),
    );
  }
}
