import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_item.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Cart tab: items grouped by store, a totals summary and a checkout CTA.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(cartGroupsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        automaticallyImplyLeading: false,
      ),
      body: groups.isEmpty
          ? const _EmptyCart()
          : Column(
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
                      for (final group in groups) ...[
                        _StoreGroup(group: group),
                        const Gap(AppSpacing.lg),
                      ],
                      _SummaryCard(subtotal: subtotal),
                    ],
                  ),
                ),
                _CheckoutBar(
                  subtotal: subtotal,
                  onCheckout: () => context.push(RouteNames.checkout),
                ),
              ],
            ),
    );
  }
}

class _StoreGroup extends StatelessWidget {
  const _StoreGroup({required this.group});

  final CartStoreGroup group;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 18,
                color: AppColors.brand.primary,
              ),
              const Gap(AppSpacing.sm),
              Text(
                group.storeName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          for (final item in group.items) _CartRow(item: item),
        ],
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          NetworkImageBox(
            url: item.product.imageUrl,
            width: 56,
            height: 56,
            borderRadius: AppRadius.brMd,
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Gap(2),
                Text(
                  Money.peso(item.product.price),
                  style: TextStyle(
                    color: AppColors.text.secondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _QtyStepper(
            quantity: item.quantity,
            onMinus: () => cart.setQuantity(item.product.id, item.quantity - 1),
            onPlus: () => cart.setQuantity(item.product.id, item.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceElevatedDark,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.ui.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity <= 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: onMinus,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: AppColors.text.primaryDark),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.subtotal});

  final num subtotal;

  static const _serviceFee = 25;

  @override
  Widget build(BuildContext context) {
    final total = subtotal + _serviceFee;
    return GlassCard(
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: Money.peso(subtotal)),
          const Gap(AppSpacing.sm),
          _SummaryRow(label: 'Service fee', value: Money.peso(_serviceFee)),
          const Gap(AppSpacing.sm),
          Divider(color: AppColors.ui.borderDark, height: 1),
          const Gap(AppSpacing.sm),
          _SummaryRow(label: 'Total', value: Money.peso(total), bold: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

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

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.subtotal, required this.onCheckout});

  final num subtotal;
  final VoidCallback onCheckout;

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
          label: 'Checkout • ${Money.peso(subtotal + 25)}',
          icon: Icons.arrow_forward_rounded,
          onPressed: onCheckout,
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 56,
            color: AppColors.text.tertiaryDark,
          ),
          const Gap(AppSpacing.md),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Add products from a store to get started.',
            style: TextStyle(color: AppColors.text.tertiaryDark),
          ),
        ],
      ),
    );
  }
}
