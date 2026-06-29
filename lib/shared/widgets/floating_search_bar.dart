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

    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: AppSpacing.md, right: 6),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceDark.withValues(alpha: 0.92),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.ui.borderDark),
        boxShadow: AppEffects.cardShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.text.secondaryDark),
          const Gap(AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              readOnly: readOnly,
              onTap: onTap,
              style: TextStyle(color: AppColors.text.primaryDark, fontSize: 15),
              cursorColor: AppColors.brand.primary,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.text.tertiaryDark),
              ),
            ),
          ),
          if (onFilterTap != null)
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
