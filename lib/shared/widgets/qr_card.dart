import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A QR code inside a card, with the pickup [code] below. Set [glow] for the
/// Pickup Pass hero treatment (solid ink frame + shadow, instead of the
/// retired gradient glow).
class QrCard extends StatelessWidget {
  const QrCard({
    required this.data,
    required this.code,
    this.glow = false,
    this.size = 220,
    super.key,
  });

  final String data;
  final String code;
  final bool glow;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: glow ? AppColors.ink : AppColors.ui.borderHairline,
        borderRadius: AppRadius.brXl,
        boxShadow: glow ? AppEffects.cardShadow : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.ui.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl - 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.brMd,
              ),
              child: QrImageView(
                data: data,
                size: size,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Text(
              'PICKUP CODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.text.tertiary,
              ),
            ),
            const Gap(4),
            Text(
              code,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.text.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
