import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Mock checkout: pickup info, payment method selection and a place-order CTA.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  static const _serviceFee = 25;
  static const _methods = <(String, IconData)>[
    ('Credit / Debit Card', Icons.credit_card_rounded),
    ('GCash', Icons.account_balance_wallet_rounded),
    ('Cash on pickup', Icons.payments_rounded),
  ];

  int _method = 0;

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final groups = ref.watch(cartGroupsProvider);
    final total = subtotal + _serviceFee;
    final storeName = groups.isNotEmpty ? groups.first.storeName : 'Store';

    return Scaffold(
      appBar: const ModernAppBar(title: 'Checkout'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                const SectionTitle(title: 'Pickup'),
                const Gap(AppSpacing.sm),
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brand.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: AppRadius.brMd,
                        ),
                        child: Icon(
                          Icons.store_mall_directory_rounded,
                          color: AppColors.brand.primary,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Ready for pickup in ~15 min',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.text.tertiaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.lg),
                const SectionTitle(title: 'Payment method'),
                const Gap(AppSpacing.sm),
                for (var i = 0; i < _methods.length; i++) ...[
                  _PaymentTile(
                    label: _methods[i].$1,
                    icon: _methods[i].$2,
                    selected: _method == i,
                    onTap: () => setState(() => _method = i),
                  ),
                  if (i < _methods.length - 1) const Gap(AppSpacing.sm),
                ],
                const Gap(AppSpacing.lg),
                const SectionTitle(title: 'Order summary'),
                const Gap(AppSpacing.sm),
                GlassCard(
                  child: Column(
                    children: [
                      _Row(label: 'Subtotal', value: Money.peso(subtotal)),
                      const Gap(AppSpacing.sm),
                      _Row(
                        label: 'Service fee',
                        value: Money.peso(_serviceFee),
                      ),
                      const Gap(AppSpacing.sm),
                      Divider(color: AppColors.ui.borderDark, height: 1),
                      const Gap(AppSpacing.sm),
                      _Row(
                        label: 'Total',
                        value: Money.peso(total),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _PlaceOrderBar(
            total: total,
            onPlaceOrder: () => _placeOrder(context),
          ),
        ],
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    ref.read(cartProvider.notifier).clear();
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.ui.surfaceDark,
          icon: Icon(
            Icons.check_circle_rounded,
            color: AppColors.status.success,
            size: 48,
          ),
          title: const Text('Order placed!'),
          content: const Text(
            'Your order is confirmed. The store is preparing it for pickup.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: PrimaryButton(
                label: 'Done',
                expand: false,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go(RouteNames.home);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.brand.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.ui.surfaceDark,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: selected ? primary : AppColors.ui.borderDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.text.secondaryDark),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? primary : AppColors.text.tertiaryDark,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.text.primaryDark : AppColors.text.secondaryDark,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({required this.total, required this.onPlaceOrder});

  final num total;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.ui.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: GradientButton(
          label: 'Place order • ${Money.peso(total)}',
          icon: Icons.lock_rounded,
          onPressed: onPlaceOrder,
        ),
      ),
    );
  }
}
