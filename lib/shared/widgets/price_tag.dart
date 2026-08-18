import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Shows a formatted price as plain bold text — the only price treatment
/// in the system (the old gradient-filled "pop" pill variant is retired
/// along with the gradient token it depended on).
class PriceTag extends StatelessWidget {
  const PriceTag({required this.amount, this.fontSize = 16, super.key});

  final num amount;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      Money.peso(amount),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: AppColors.text.primary,
        letterSpacing: -0.3,
      ),
    );
  }
}
