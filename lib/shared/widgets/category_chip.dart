import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/shared/widgets/selectable_row.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A selectable pill chip for categories / filters — the pill-shaped
/// sibling of [SelectableRow]. Same fill/text inversion rule, just pill
/// radius and compact padding.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SelectableRow(
      selected: selected,
      onTap: onTap,
      label: label,
      icon: icon,
      iconSize: 16,
      borderRadius: AppRadius.brPill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}
