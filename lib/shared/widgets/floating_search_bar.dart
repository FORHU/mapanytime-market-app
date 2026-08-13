import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A floating glass search bar for the map and list screens.
///
/// Pass [onTap] to use it as a tappable button (e.g. opens a search screen);
/// otherwise provide a [controller]/[onChanged] for inline editing.
class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    this.hint = 'Search stores or products...',
    this.controller,
    this.onChanged,
    this.onTap,
    this.onFilterTap,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;

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
        color: AppColors.ui.surfaceDark.withValues(alpha: 0.92),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.ui.borderDark),
        boxShadow: AppEffects.cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.text.secondaryDark,
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              readOnly: readOnly,
              onTap: onTap,
              style: baseStyle?.copyWith(color: AppColors.text.primaryDark),
              cursorColor: AppColors.brand.primary,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                hintText: hint,
                hintStyle: baseStyle?.copyWith(
                  color: AppColors.text.tertiaryDark,
                ),
              ),
            ),
          ),
          if (hasFilter)
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.brPill,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
