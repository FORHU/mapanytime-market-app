import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// A circular colorful category shortcut: tinted icon disc + label.
class QuickCategoryItem extends StatelessWidget {
  const QuickCategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Material(
            color: color.withValues(alpha: 0.16),
            shape: CircleBorder(
              side: BorderSide(color: color.withValues(alpha: 0.30)),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(icon, color: color, size: 26),
              ),
            ),
          ),
          const Gap(8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text.secondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
