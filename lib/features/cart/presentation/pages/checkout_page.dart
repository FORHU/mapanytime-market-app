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
import 'package:mapanytime_market_app/features/payments/domain/entities/payment_method.dart';
import 'package:mapanytime_market_app/features/payments/presentation/controllers/payment_controller.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/user_voucher.dart';
import 'package:mapanytime_market_app/features/rewards/presentation/controllers/rewards_controller.dart';
import 'package:mapanytime_market_app/features/rewards/presentation/widgets/claimed_voucher_card.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/key_value_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/price_breakdown_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/breakpoints.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checkout: pickup info, live server-priced payment method selection, an
/// order-items summary, a server-verified price breakdown with per-method
/// gateway fees, and a place-order CTA.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  PaymentMethod? _selectedMethod;
  TimeOfDay? _pickupTime;
  bool _isSubmitting = false;
  UserVoucher? _selectedVoucher;

  Future<void> _pickVoucher(num eligibleSubtotal) async {
    final usable = ref
        .read(usableVouchersProvider)
        .where((v) => v.voucher.meetsMinimum(eligibleSubtotal))
        .toList();

    // Wrapped in [_VoucherPickResult] so a swipe-to-dismiss (no explicit
    // choice, resolves to plain `null`) is distinguishable from an explicit
    // "Remove applied voucher" tap (resolves to a result wrapping `null`) —
    // otherwise dismissing the sheet would silently clear an already-applied
    // voucher.
    final result = await showModalBottomSheet<_VoucherPickResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VoucherPickerSheet(
        vouchers: usable,
        selected: _selectedVoucher,
      ),
    );

    if (result != null) {
      setState(() => _selectedVoucher = result.voucher);
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? now.replacing(hour: (now.hour + 1) % 24),
      helpText: 'Select pickup time',
    );
    if (picked != null) {
      setState(() => _pickupTime = picked);
    }
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

    final goodsTotal = pricing.hasValue && pricing.value != null
        ? pricing.value!.totalAmount.toDouble()
        : 0.0;
    final methodsAsync = ref.watch(paymentMethodsProvider(goodsTotal));

    // Eligible base for both the voucher discount preview and the points-to-
    // earn estimate: subtotal net of merchant discounts, matching what the
    // backend uses for each (RewardService reads the same base; a MapPoints
    // voucher deliberately does not shrink it further — see F39/F40).
    final eligibleSubtotal = pricing.hasValue && pricing.value != null
        ? (pricing.value!.subtotalAmount - pricing.value!.discountAmount)
        : 0;
    final selectedVoucher = _selectedVoucher;
    final voucherDiscount = selectedVoucher != null
        ? selectedVoucher.voucher.estimateDiscount(eligibleSubtotal)
        : 0;
    final rewardsConfig = ref.watch(rewardsConfigProvider).value;
    final pointsToEarn = rewardsConfig?.estimatePoints(eligibleSubtotal) ?? 0;

    ref.listen(paymentMethodsProvider(goodsTotal), (prev, next) {
      next.whenData((methods) {
        if (methods.isNotEmpty) {
          final currentValid =
              _selectedMethod != null &&
              methods.any((m) => m.id == _selectedMethod!.id && m.available);
          if (!currentValid) {
            final firstAvailable = methods
                .where((m) => m.available)
                .firstOrNull;
            if (firstAvailable != null &&
                _selectedMethod?.id != firstAvailable.id) {
              setState(() => _selectedMethod = firstAvailable);
            }
          }
        }
      });
    });

    final canPlaceOrder =
        !_isSubmitting &&
        pricing.hasValue &&
        pricing.value != null &&
        _selectedMethod != null &&
        _selectedMethod!.available;

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
                methodsAsync: methodsAsync,
                selectedMethod: _selectedMethod,
                onMethodChanged: (method) {
                  setState(() => _selectedMethod = method);
                },
                onRetryMethods: () {
                  ref.invalidate(paymentMethodsProvider(goodsTotal));
                },
                items: items,
                selectedVoucher: selectedVoucher,
                onPickVoucher: () => unawaited(_pickVoucher(eligibleSubtotal)),
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
                            selectedMethod: _selectedMethod,
                            onRetry: () => ref.invalidate(cartPricingProvider),
                            voucherDiscountAmount: voucherDiscount > 0
                                ? voucherDiscount
                                : null,
                            pointsToEarn: pointsToEarn > 0
                                ? pointsToEarn
                                : null,
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
                            selectedMethod: _selectedMethod,
                            onRetry: () => ref.invalidate(cartPricingProvider),
                            voucherDiscountAmount: voucherDiscount > 0
                                ? voucherDiscount
                                : null,
                            pointsToEarn: pointsToEarn > 0
                                ? pointsToEarn
                                : null,
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

    final method = _selectedMethod;
    if (method == null || !method.available) {
      showTopToast(context, 'Please choose an available payment method.');
      return;
    }

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

    final finalPickup = pickupDateTime.isBefore(now)
        ? pickupDateTime.add(const Duration(days: 1))
        : pickupDateTime;
    final isoPickup = finalPickup.toUtc().toIso8601String();

    final orderedIds = [
      for (final item in ref.read(cartSelectedItemsProvider)) item.product.id,
    ];
    final orderPricing = ref.read(cartPricingProvider).value!;

    try {
      final api = ref.read(apiServiceProvider);
      final remote = OrderRemoteDataSource(api);

      final result = await remote.createOrder(
        type: 'PICKUP',
        pickupAt: isoPickup,
        paymentMethodId: method.id,
        paymentMethod: method.code,
        productIds: orderedIds,
        userVoucherId: _selectedVoucher?.id,
      );

      ref.read(cartProvider.notifier).removeMany(orderedIds);
      ref.invalidate(ordersProvider);
      if (_selectedVoucher != null) {
        // The voucher is now USED server-side — refresh so it stops
        // appearing as applicable on the next checkout.
        ref.invalidate(myVouchersControllerProvider);
      }

      if (result.checkoutUrl != null && result.checkoutUrl!.isNotEmpty) {
        final uri = Uri.parse(result.checkoutUrl!);
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } on Object catch (_) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (!context.mounted) return;

      context.go(
        RouteNames.orderConfirmation,
        extra: OrderConfirmationArgs(
          orderId: result.orderId,
          paymentMethodLabel: method.name,
          isCashOnDelivery: method.isCash,
          pricing: orderPricing,
          selectedMethod: method,
          checkoutUrl: result.checkoutUrl,
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
    required this.methodsAsync,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.onRetryMethods,
    required this.items,
    required this.selectedVoucher,
    required this.onPickVoucher,
  });

  final String storeName;
  final String pickupLabel;
  final bool pickupSet;
  final VoidCallback onPickTime;
  final AsyncValue<List<PaymentMethod>> methodsAsync;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final VoidCallback onRetryMethods;
  final List<CartItem> items;
  final UserVoucher? selectedVoucher;
  final VoidCallback onPickVoucher;

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
        methodsAsync.when(
          loading: () => const _PaymentMethodsSkeleton(),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.ui.surfaceMuted,
              borderRadius: AppRadius.brLg,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.status.error,
                  size: 20,
                ),
                const Gap(AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Unable to load payment methods.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: onRetryMethods,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (methods) => Column(
            children: [
              for (var i = 0; i < methods.length; i++) ...[
                _PaymentMethodRow(
                  method: methods[i],
                  selected: selectedMethod?.id == methods[i].id,
                  onTap: () => onMethodChanged(methods[i]),
                ),
                if (i < methods.length - 1) const Gap(AppSpacing.sm),
              ],
            ],
          ),
        ),
        const Gap(AppSpacing.lg),
        const SectionTitle(title: 'MapPoints voucher'),
        const Gap(AppSpacing.sm),
        if (selectedVoucher != null)
          ClaimedVoucherCard(
            userVoucher: selectedVoucher!,
            selected: true,
            onApply: onPickVoucher,
          )
        else
          GestureDetector(
            onTap: onPickVoucher,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.ui.surfaceMuted,
                borderRadius: AppRadius.brLg,
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 20),
                  const Gap(AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Apply a MapPoints voucher',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.text.tertiary,
                  ),
                ],
              ),
            ),
          ),
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

/// Wraps the sheet's explicit result — see [_CheckoutPageState._pickVoucher]
/// for why this can't just be a bare `UserVoucher?`.
class _VoucherPickResult {
  const _VoucherPickResult(this.voucher);
  final UserVoucher? voucher;
}

/// Bottom sheet listing claimed vouchers usable on this basket (ACTIVE,
/// unexpired, and meeting the voucher's own minimum spend — already filtered
/// by the caller). Returns the picked voucher, `null` to clear a selection,
/// or nothing (sheet dismissed) to leave the current selection untouched.
class _VoucherPickerSheet extends StatelessWidget {
  const _VoucherPickerSheet({required this.vouchers, this.selected});

  final List<UserVoucher> vouchers;
  final UserVoucher? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a MapPoints voucher',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(AppSpacing.sm),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TextButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(const _VoucherPickResult(null)),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Remove applied voucher'),
                ),
              ),
            if (vouchers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No claimed vouchers apply to this order.',
                  style: TextStyle(color: AppColors.text.secondary),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vouchers.length,
                  separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                  itemBuilder: (context, i) => ClaimedVoucherCard(
                    userVoucher: vouchers[i],
                    selected: selected?.id == vouchers[i].id,
                    onApply: () => Navigator.of(
                      context,
                    ).pop(_VoucherPickResult(vouchers[i])),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  IconData _iconForMethod(PaymentMethod method) {
    final code = method.code.toUpperCase();
    final type = method.type.toUpperCase();
    if (method.isCash ||
        type == 'CASH' ||
        code == 'COD' ||
        code == 'CASH_ON_DELIVERY') {
      return Icons.payments_rounded;
    }
    if (code.contains('GCASH')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (code.contains('MAYA')) {
      return Icons.wallet_rounded;
    }
    if (code.contains('CARD') || type == 'CARD') {
      return Icons.credit_card_rounded;
    }
    if (code.contains('QRPH') || code.contains('QR')) {
      return Icons.qr_code_2_rounded;
    }
    if (code.contains('GRAB')) {
      return Icons.account_balance_wallet_rounded;
    }
    return Icons.payment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = method.available;
    final contentColor = selected
        ? AppColors.text.onInk
        : (isAvailable ? AppColors.text.primary : AppColors.text.tertiary);

    final icon = _iconForMethod(method);

    String? subtitle;
    Color? subtitleColor;

    if (!isAvailable && method.unavailableReason != null) {
      subtitle = method.unavailableReason;
      subtitleColor = selected
          ? AppColors.text.onInk.withValues(alpha: 0.8)
          : AppColors.status.error;
    } else if (method.isCash) {
      subtitle = 'Pay in cash when you collect at the stall (no fee)';
      subtitleColor = selected
          ? AppColors.text.onInk.withValues(alpha: 0.8)
          : AppColors.text.secondary;
    } else if (method.feeAmount != null && method.buyerTotalAmount != null) {
      final fee = Money.peso(method.feeAmount!);
      final total = Money.peso(method.buyerTotalAmount!);
      subtitle = '+$fee fee · Total: $total';
      subtitleColor = selected
          ? AppColors.text.onInk.withValues(alpha: 0.8)
          : AppColors.text.secondary;
    }

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: isAvailable ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.ui.surfaceMuted,
            borderRadius: AppRadius.brLg,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: contentColor),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      method.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: contentColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const Gap(2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor,
                          fontWeight: !isAvailable
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : (isAvailable
                          ? Icons.circle_outlined
                          : Icons.block_rounded),
                size: 20,
                color: contentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodsSkeleton extends StatelessWidget {
  const _PaymentMethodsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.ui.surfaceMuted,
              borderRadius: AppRadius.brLg,
            ),
          ),
          if (i == 0) const Gap(AppSpacing.sm),
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
