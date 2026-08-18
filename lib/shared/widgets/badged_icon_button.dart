import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// A solid-ink circular icon button carrying a small count badge — the
/// notification bell on Home, the cart glyph on the Cart header.
class BadgedIconButton extends StatelessWidget {
  const BadgedIconButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: size * 0.5, color: AppColors.text.onInk),
              if (badgeCount > 0)
                Positioned(
                  top: size * 0.15,
                  right: size * 0.1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.status.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text.onInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
