import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_item.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/badged_icon_button.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/price_breakdown_card.dart';
import 'package:mapanytime_market_app/theme/tokens/breakpoints.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Cart tab: items grouped by store, a server-verified price breakdown and
/// a checkout CTA. Two layouts: single column on phones, a two-pane
/// items+summary split at [AppBreakpoints.tablet] and above.
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  @override
  void initState() {
    super.initState();
    // Opening the cart clears the unseen badge on the nav. Deferred so we don't
    // mutate providers during the build/mount phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(cartSeenProvider.notifier).markSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(cartGroupsProvider);
    final pricing = ref.watch(cartPricingProvider);
    final selectedCount = ref.watch(cartSelectedCountProvider);
    final selectedStoreCount = ref.watch(cartSelectedStoreCountProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: ModernAppBar(
        title: context.l10n.cart,
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: BadgedIconButton(
              icon: Icons.shopping_bag_outlined,
              badgeCount: cartCount,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(cartPricingProvider),
        color: AppColors.ink,
        child: groups.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Gap(200), _EmptyCart()],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
                  return isWide
                      ? _WideLayout(
                          groups: groups,
                          pricing: pricing,
                          selectedCount: selectedCount,
                          selectedStoreCount: selectedStoreCount,
                        )
                      : _NarrowLayout(
                          groups: groups,
                          pricing: pricing,
                          selectedCount: selectedCount,
                          selectedStoreCount: selectedStoreCount,
                        );
                },
              ),
      ),
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({
    required this.groups,
    required this.pricing,
    required this.selectedCount,
    required this.selectedStoreCount,
  });

  final List<CartStoreGroup> groups;
  final AsyncValue<CartPricing?> pricing;
  final int selectedCount;

  /// Above 1, checkout is blocked: an order cannot span stores.
  final int selectedStoreCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              for (final group in groups) ...[
                _StoreGroup(group: group, pricing: pricing),
                const Gap(AppSpacing.lg),
              ],
              PriceBreakdownCard(
                pricing: pricing,
                onRetry: () => ref.invalidate(cartPricingProvider),
              ),
            ],
          ),
        ),
        _CheckoutBar(
          enabled:
              selectedCount > 0 && pricing.hasValue && selectedStoreCount <= 1,
          spansMultipleStores: selectedStoreCount > 1,
          onCheckout: () => context.push(RouteNames.checkout),
        ),
      ],
    );
  }
}

class _WideLayout extends ConsumerWidget {
  const _WideLayout({
    required this.groups,
    required this.pricing,
    required this.selectedCount,
    required this.selectedStoreCount,
  });

  final List<CartStoreGroup> groups;
  final AsyncValue<CartPricing?> pricing;
  final int selectedCount;

  /// Above 1, checkout is blocked: an order cannot span stores.
  final int selectedStoreCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final group in groups) ...[
                _StoreGroup(group: group, pricing: pricing),
                const Gap(AppSpacing.lg),
              ],
            ],
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
                PriceBreakdownCard(
                  pricing: pricing,
                  onRetry: () => ref.invalidate(cartPricingProvider),
                ),
                const Gap(AppSpacing.md),
                PrimaryButton(
                  label: checkoutCtaLabel(
                    selectedCount: selectedCount,
                    spansMultipleStores: selectedStoreCount > 1,
                  ),
                  icon: Icons.arrow_forward_rounded,
                  onPressed:
                      selectedCount > 0 &&
                          pricing.hasValue &&
                          selectedStoreCount <= 1
                      ? () => context.push(RouteNames.checkout)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreGroup extends ConsumerWidget {
  const _StoreGroup({required this.group, required this.pricing});

  final CartStoreGroup group;
  final AsyncValue<CartPricing?> pricing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deselected = ref.watch(cartDeselectedProvider);
    final ids = [for (final item in group.items) item.product.id];
    final allSelected = ids.every((id) => !deselected.contains(id));
    final byProductId = pricing.value?.byProductId ?? const {};

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 18,
                color: AppColors.ink,
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  group.storeName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Checkbox(
                value: allSelected,
                onChanged: (value) => ref
                    .read(cartDeselectedProvider.notifier)
                    .setManySelected(ids, selected: value ?? false),
                activeColor: AppColors.ink,
                side: BorderSide(color: AppColors.ui.borderHairline),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          for (final item in group.items)
            _CartRow(
              key: ValueKey(item.product.id),
              item: item,
              discount: byProductId[item.product.id],
            ),
        ],
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({required this.item, this.discount, super.key});

  final CartItem item;
  final CartItemPricing? discount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    final selected = !ref
        .watch(cartDeselectedProvider)
        .contains(item.product.id);
    final hasDiscount = (discount?.discountAmount ?? 0) > 0;

    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.remove(item.product.id),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: AppRadius.brMd,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.text.onInk,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: (value) => ref
                  .read(cartDeselectedProvider.notifier)
                  .setSelected(item.product.id, selected: value ?? false),
              activeColor: AppColors.ink,
              side: BorderSide(color: AppColors.ui.borderHairline),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const Gap(AppSpacing.xs),
            Stack(
              children: [
                NetworkImageBox(
                  url: item.product.imageUrl,
                  width: 56,
                  height: 56,
                  borderRadius: AppRadius.brMd,
                ),
                if (hasDiscount)
                  Positioned(
                    top: -4,
                    left: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.status.warning,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(
                        'SALE',
                        style: TextStyle(
                          color: AppColors.text.onInk,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
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
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      Text(
                        Money.peso(item.product.price),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.text.secondary,
                          decoration: hasDiscount
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const Gap(6),
                        Text(
                          '-${Money.peso(discount!.discountAmount)}',
                          style:
                              Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: AppColors.status.success,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                  if ((discount?.freeUnits ?? 0) > 0) ...[
                    const Gap(2),
                    Text(
                      '+${discount!.freeUnits} free',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.status.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _QtyStepper(
              quantity: item.quantity,
              onMinus: () =>
                  cart.setQuantity(item.product.id, item.quantity - 1),
              onPlus: () =>
                  cart.setQuantity(item.product.id, item.quantity + 1),
            ),
          ],
        ),
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
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceMuted,
        borderRadius: AppRadius.brPill,
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
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        width: 30,
        height: 32,
        child: Icon(icon, size: 16, color: AppColors.text.primary),
      ),
    );
  }
}

/// Label for the checkout CTA, which doubles as the reason when the CTA is
/// disabled — a selection spanning stores reads differently from an empty one,
/// and the buyer needs to know which of the two is blocking them.
@visibleForTesting
String checkoutCtaLabel({
  required int selectedCount,
  required bool spansMultipleStores,
}) {
  if (spansMultipleStores) return 'Select items from one store';
  if (selectedCount > 0) return 'Review payment method';
  return 'Select items to checkout';
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.enabled,
    required this.spansMultipleStores,
    required this.onCheckout,
  });

  final bool enabled;
  final bool spansMultipleStores;
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
        color: AppColors.ui.surface,
        boxShadow: AppEffects.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: checkoutCtaLabel(
            selectedCount: enabled ? 1 : 0,
            spansMultipleStores: spansMultipleStores,
          ),
          icon: Icons.arrow_forward_rounded,
          onPressed: enabled ? onCheckout : null,
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
            color: AppColors.text.tertiary,
          ),
          const Gap(AppSpacing.md),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Add products from a store to get started.',
            style: TextStyle(color: AppColors.text.tertiary),
          ),
        ],
      ),
    );
  }
}
