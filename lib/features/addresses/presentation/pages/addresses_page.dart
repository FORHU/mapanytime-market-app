import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/addresses/domain/entities/buyer_address.dart';
import 'package:mapanytime_market_app/features/addresses/presentation/controllers/addresses_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/app_state_view.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// `Profile → Addresses`: the buyer's saved addresses, default first.
class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  void _openForm(BuildContext context, [BuyerAddress? address]) =>
      unawaited(context.push(RouteNames.addressForm, extra: address));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesControllerProvider);
    final hasAny = addresses.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: const ModernAppBar(title: 'Addresses'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(addressesControllerProvider.future),
        color: AppColors.ink,
        child: addresses.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.ink),
          ),
          error: (_, _) => _Scrollable(
            child: AppStateView(
              kind: AppStateKind.error,
              title: "Couldn't load your addresses",
              message: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(addressesControllerProvider),
            ),
          ),
          data: (list) => list.isEmpty
              ? _Scrollable(
                  child: AppStateView(
                    kind: AppStateKind.empty,
                    icon: Icons.location_on_outlined,
                    title: 'No saved addresses',
                    message: 'Add an address so it is ready when you need it.',
                    actionLabel: 'Add address',
                    onAction: () => _openForm(context),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _AddressCard(
                    address: list[i],
                    onEdit: () => _openForm(context, list[i]),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: hasAny
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: PrimaryButton(
                label: 'Add address',
                icon: Icons.add_rounded,
                onPressed: () => _openForm(context),
              ),
            )
          : null,
    );
  }
}

/// Keeps pull-to-refresh working on a non-list state.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

enum _CardAction { edit, makeDefault, delete }

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address, required this.onEdit});

  final BuyerAddress address;
  final VoidCallback onEdit;

  IconData get _icon => switch (address.type) {
    AddressType.home => Icons.home_outlined,
    AddressType.office => Icons.business_outlined,
    AddressType.billing => Icons.receipt_long_outlined,
  };

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _CardAction action,
  ) async {
    final controller = ref.read(addressesControllerProvider.notifier);
    switch (action) {
      case _CardAction.edit:
        onEdit();
      case _CardAction.makeDefault:
        final ok = await controller.setDefault(address.id);
        if (!context.mounted) return;
        showTopToast(
          context,
          ok
              ? 'Default address updated'
              : "Couldn't change the default address. Try again.",
        );
      case _CardAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this address?'),
            content: Text(address.displayLine),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                key: const ValueKey('confirmDeleteAddress'),
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.status.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        final ok = await controller.remove(address.id);
        if (!context.mounted) return;
        showTopToast(
          context,
          ok ? 'Address deleted' : "Couldn't delete the address. Try again.",
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      key: ValueKey('address-${address.id}'),
      border: true,
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 22, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      const _DefaultBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    address.recipientName,
                    formatPhone(address.phoneNumber),
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address.displayLine,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          PopupMenuButton<_CardAction>(
            key: ValueKey('addressMenu-${address.id}'),
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppColors.text.secondary,
            ),
            onSelected: (action) => unawaited(_onAction(context, ref, action)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: _CardAction.edit, child: Text('Edit')),
              if (!address.isDefault)
                const PopupMenuItem(
                  value: _CardAction.makeDefault,
                  child: Text('Set as default'),
                ),
              PopupMenuItem(
                value: _CardAction.delete,
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.status.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Default',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.text.onInk,
        ),
      ),
    );
  }
}

/// `+639171234567` → `+63 917 123 4567`; anything else is shown as stored.
String formatPhone(String e164) {
  final m = RegExp(r'^\+63(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
  return m == null ? e164 : '+63 ${m[1]} ${m[2]} ${m[3]}';
}
