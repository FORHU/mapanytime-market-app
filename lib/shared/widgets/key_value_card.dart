import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A label/value row for a [KeyValueCard]. Pass [onTap] for an editable row
/// (e.g. Checkout's pickup time) — it renders a trailing chevron and
/// becomes tappable; [valueColor] overrides the default muted value color
/// (e.g. to highlight a value that's been set).
class KeyValueRow {
  const KeyValueRow(this.label, this.value, {this.onTap, this.valueColor});

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;
}

/// A card of bold-label / plain-value row pairs — pickup details on
/// Checkout, order-tracking summaries. A thin preset over [GlassCard].
class KeyValueCard extends StatelessWidget {
  const KeyValueCard({required this.rows, super.key});

  final List<KeyValueRow> rows;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Gap(AppSpacing.sm),
            _Row(row: rows[i], tt: tt),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.tt});

  final KeyValueRow row;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.label,
          style: tt.titleSmall?.copyWith(color: AppColors.text.primary),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: tt.bodyMedium?.copyWith(
              color: row.valueColor ?? AppColors.text.secondary,
            ),
          ),
        ),
        if (row.onTap != null) ...[
          const Gap(4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.text.tertiary,
          ),
        ],
      ],
    );

    if (row.onTap == null) return content;
    return GestureDetector(
      onTap: row.onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
