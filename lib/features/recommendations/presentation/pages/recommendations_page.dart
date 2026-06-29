import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// "For You" tab — personalised picks. Placeholder content for now (the
/// recommendation engine isn't wired yet), styled to match the design system.
class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppEffects.primaryGlow,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const Gap(AppSpacing.lg),
              Text(
                'Personalised picks are on the way',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Gap(AppSpacing.sm),
              Text(
                'Shop a few stores and we’ll start recommending '
                'products and shops tailored to you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: AppColors.text.secondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
