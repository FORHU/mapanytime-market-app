import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Shows a formatted price. As a plain bold label by default, or a gradient
/// pill when [filled] is true (e.g. map price markers).
class PriceTag extends StatelessWidget {
  const PriceTag({
    required this.amount,
    this.filled = false,
    this.fontSize = 16,
    super.key,
  });

  final num amount;
  final bool filled;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final text = Money.peso(amount);

    if (!filled) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.text.primaryDark,
          letterSpacing: -0.3,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize - 3,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
