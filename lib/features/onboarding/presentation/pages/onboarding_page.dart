import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// First-run onboarding — a short intro shown once to new users, then gated
/// off via a local flag (`StorageService.onboardingSeen`).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.map_rounded,
      title: 'Discover stores\naround you',
      body:
          'Explore a live map of shops nearby and find exactly '
          'what you need.',
    ),
    _Slide(
      icon: Icons.shopping_bag_rounded,
      title: 'Order in a tap',
      body:
          'Browse products from any store and add them to your '
          'cart in seconds.',
    ),
    _Slide(
      icon: Icons.qr_code_rounded,
      title: 'Skip the line',
      body:
          'Show your QR pickup pass at the counter and grab '
          'your order — no waiting.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(storageServiceProvider).setOnboardingSeen();
    if (mounted) context.go(RouteNames.home);
  }

  void _next() {
    if (_isLast) {
      unawaited(_finish());
    } else {
      unawaited(
        _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(color: AppColors.text.secondary),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? AppColors.ink
                          : AppColors.ui.borderHairline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
            const Gap(AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: PrimaryButton(
                label: _isLast ? 'Get Started' : 'Next',
                icon: _isLast
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
              boxShadow: AppEffects.cardShadow,
            ),
            child: Icon(slide.icon, size: 60, color: AppColors.text.onInk),
          ),
          const Gap(AppSpacing.xl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Gap(AppSpacing.md),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.text.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
