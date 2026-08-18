import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_item.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/features/orders/data/order_remote_datasource.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_confirmation_page.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/key_value_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/price_breakdown_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/shared/widgets/selectable_row.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/breakpoints.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Checkout: pickup info, payment method selection, an order-items summary,
/// a server-verified price breakdown, and a place-order CTA. Two layouts:
/// single column on phones, a two-pane form+summary split at
/// [AppBreakpoints.tablet] and above.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

const _paymentMethods = <(String, IconData, String)>[
  ('Payment on pickup', Icons.payments_rounded, 'CASH_ON_DELIVERY'),
  ('GCash', Icons.account_balance_wallet_rounded, 'GCASH'),
];

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  int _method = 0;
  TimeOfDay? _pickupTime;
  bool _isSubmitting = false;

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? now.replacing(hour: (now.hour + 1) % 24),
      helpText: 'Select pickup time',
    );
    if (picked != null) setState(() => _pickupTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(cartSelectedGroupsProvider);
    final pricing = ref.watch(cartPricingProvider);
    final storeName = groups.isNotEmpty ? groups.first.storeName : 'Store';
    final items = [for (final g in groups) ...g.items];
    final pickupLabel = _pickupTime == null
        ? 'Select a time'
        : MaterialLocalizations.of(context).formatTimeOfDay(_pickupTime!);
    final canPlaceOrder =
        !_isSubmitting && pricing.hasValue && pricing.value != null;

    return Stack(
      children: [
        Scaffold(
          appBar: const ModernAppBar(title: 'Checkout'),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
              final formSections = _FormSections(
                storeName: storeName,
                pickupLabel: pickupLabel,
                pickupSet: _pickupTime != null,
                onPickTime: _pickTime,
                method: _method,
                onMethodChanged: (i) => setState(() => _method = i),
                items: items,
              );

              if (!isWide) {
                return Column(
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
                          formSections,
                          const Gap(AppSpacing.lg),
                          const SectionTitle(title: 'Order summary'),
                          const Gap(AppSpacing.sm),
                          PriceBreakdownCard(
                            pricing: pricing,
                            onRetry: () => ref.invalidate(cartPricingProvider),
                          ),
                        ],
                      ),
                    ),
                    _PlaceOrderBar(
                      enabled: canPlaceOrder,
                      onPlaceOrder: () => unawaited(_placeOrder(context)),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [formSections],
                    ),
                  ),
                  SizedBox(
                    width: 380,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionTitle(title: 'Order summary'),
                          const Gap(AppSpacing.sm),
                          PriceBreakdownCard(
                            pricing: pricing,
                            onRetry: () => ref.invalidate(cartPricingProvider),
                          ),
                          const Gap(AppSpacing.md),
                          PrimaryButton(
                            label: 'Place order',
                            icon: Icons.lock_rounded,
                            onPressed: canPlaceOrder
                                ? () => unawaited(_placeOrder(context))
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_isSubmitting)
          const ModalBarrier(
            dismissible: false,
            color: Color(0x99000000),
          ),
        if (_isSubmitting)
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.ui.surface,
                borderRadius: AppRadius.brCard,
                boxShadow: AppEffects.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.ink),
                  const Gap(AppSpacing.md),
                  Text(
                    'Placing your order...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.text.primary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Please wait a moment to prevent duplicates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (_isSubmitting) return;

    if (_pickupTime == null) {
      await _pickTime();
      if (_pickupTime == null) return;
    }
    if (!context.mounted) return;

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final pickupDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );

    // If picked time is before now, assume it's for tomorrow.
    final finalPickup = pickupDateTime.isBefore(now)
        ? pickupDateTime.add(const Duration(days: 1))
        : pickupDateTime;
    final isoPickup = finalPickup.toUtc().toIso8601String();

    final paymentMethodEnum = _paymentMethods[_method].$3;
    final orderedIds = [
      for (final item in ref.read(cartSelectedItemsProvider)) item.product.id,
    ];
    // Captured before removeMany() below, which can invalidate
    // cartPricingProvider (it re-derives from the now-changed selection).
    final orderPricing = ref.read(cartPricingProvider).value!;

    try {
      final api = ref.read(apiServiceProvider);
      final remote = OrderRemoteDataSource(api);

      // Only the selected items are charged — the backend leaves everything
      // else in the buyer's cart.
      final orderId = await remote.createOrder(
        type: 'PICKUP',
        paymentMethod: paymentMethodEnum,
        pickupAt: isoPickup,
        productIds: orderedIds,
      );

      // Remove only what was actually ordered — deselected items stay in
      // the cart, matching what the backend just did.
      ref.read(cartProvider.notifier).removeMany(orderedIds);
      ref.invalidate(ordersProvider);

      if (!context.mounted) return;

      context.go(
        RouteNames.orderConfirmation,
        extra: OrderConfirmationArgs(
          orderId: orderId,
          paymentMethodLabel: _paymentMethods[_method].$1,
          isCashOnDelivery: paymentMethodEnum == 'CASH_ON_DELIVERY',
          pricing: orderPricing,
        ),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      showTopToast(context, context.l10n.orderPlacedFailed(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Pickup + payment-method + order-items sections, shared between the
/// narrow and wide layouts (only their surrounding container differs).
class _FormSections extends StatelessWidget {
  const _FormSections({
    required this.storeName,
    required this.pickupLabel,
    required this.pickupSet,
    required this.onPickTime,
    required this.method,
    required this.onMethodChanged,
    required this.items,
  });

  final String storeName;
  final String pickupLabel;
  final bool pickupSet;
  final VoidCallback onPickTime;
  final int method;
  final ValueChanged<int> onMethodChanged;
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Pickup'),
        const Gap(AppSpacing.sm),
        KeyValueCard(
          rows: [
            KeyValueRow('Store', storeName),
            KeyValueRow(
              'Pickup time',
              pickupLabel,
              onTap: onPickTime,
              valueColor: pickupSet ? AppColors.ink : null,
            ),
          ],
        ),
        const Gap(AppSpacing.lg),
        const SectionTitle(title: 'Payment method'),
        const Gap(AppSpacing.sm),
        for (var i = 0; i < _paymentMethods.length; i++) ...[
          SelectableRow(
            label: _paymentMethods[i].$1,
            icon: _paymentMethods[i].$2,
            selected: method == i,
            showCheck: true,
            onTap: () => onMethodChanged(i),
          ),
          if (i < _paymentMethods.length - 1) const Gap(AppSpacing.sm),
        ],
        if (items.isNotEmpty) ...[
          const Gap(AppSpacing.lg),
          const SectionTitle(title: 'Order items'),
          const Gap(AppSpacing.sm),
          _OrderItemsCard(items: items),
        ],
      ],
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        borderRadius: AppRadius.brCard,
        boxShadow: AppEffects.cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Gap(AppSpacing.sm),
            _OrderItemRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NetworkImageBox(
          url: item.product.imageUrl,
          width: 40,
          height: 40,
          borderRadius: AppRadius.brSm,
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: Text(
            item.product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Gap(AppSpacing.sm),
        Text(
          Money.peso(item.lineTotal),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({required this.enabled, required this.onPlaceOrder});

  final bool enabled;
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
        color: AppColors.ui.surface,
        boxShadow: AppEffects.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: 'Place order',
          icon: Icons.lock_rounded,
          onPressed: enabled ? onPlaceOrder : null,
        ),
      ),
    );
  }
}
