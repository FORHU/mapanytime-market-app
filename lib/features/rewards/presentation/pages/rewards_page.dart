import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_voucher.dart';
import 'package:mapanytime_market_app/features/rewards/presentation/controllers/rewards_controller.dart';
import 'package:mapanytime_market_app/features/rewards/presentation/widgets/claimed_voucher_card.dart';
import 'package:mapanytime_market_app/features/rewards/presentation/widgets/transaction_tile.dart';
import 'package:mapanytime_market_app/features/rewards/presentation/widgets/voucher_card.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// MapPoints home: wallet balance, the voucher catalog, claimed vouchers, and
/// the points ledger.
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: ModernAppBar(title: 'MapPoints'),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _WalletHeader(),
            ),
            Gap(AppSpacing.sm),
            TabBar(
              tabs: [
                Tab(text: 'Catalog'),
                Tab(text: 'My Vouchers'),
                Tab(text: 'History'),
              ],
              labelColor: AppColors.ink,
              indicatorColor: AppColors.ink,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _CatalogTab(),
                  _MyVouchersTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletHeader extends ConsumerWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);

    return GlassCard(
      color: AppColors.ink,
      child: wallet.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (_, _) => Text(
          "Couldn't load your balance.",
          style: TextStyle(color: AppColors.text.onInk),
        ),
        data: (value) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${value.balance} pts',
                    style: TextStyle(
                      color: AppColors.text.onInk,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '≈ ${Money.peso(value.estimatedValuePhp)} in vouchers',
                    style: TextStyle(
                      color: AppColors.text.onInk.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.toll_rounded,
              color: AppColors.text.onInk.withValues(alpha: 0.7),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(voucherCatalogControllerProvider);
    final balance = ref.watch(mapPointsBalanceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(voucherCatalogControllerProvider)
          ..invalidate(walletControllerProvider);
      },
      color: AppColors.ink,
      child: catalog.when(
        loading: () => const _CenteredSpinner(),
        error: (_, _) => const _CenteredMessage(
          icon: Icons.error_outline_rounded,
          message: "Couldn't load the voucher catalog.",
        ),
        data: (vouchers) => vouchers.isEmpty
            ? const _CenteredMessage(
                icon: Icons.local_offer_outlined,
                message: 'No vouchers available right now.',
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: vouchers.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, i) => _ClaimableVoucherRow(
                  voucher: vouchers[i],
                  balance: balance,
                ),
              ),
      ),
    );
  }
}

class _ClaimableVoucherRow extends ConsumerStatefulWidget {
  const _ClaimableVoucherRow({required this.voucher, required this.balance});

  final RewardVoucher voucher;
  final int balance;

  @override
  ConsumerState<_ClaimableVoucherRow> createState() =>
      _ClaimableVoucherRowState();
}

class _ClaimableVoucherRowState extends ConsumerState<_ClaimableVoucherRow> {
  bool _isClaiming = false;

  Future<void> _claim() async {
    setState(() => _isClaiming = true);
    try {
      await ref
          .read(voucherCatalogControllerProvider.notifier)
          .claim(widget.voucher.id);
      if (!mounted) return;
      showTopToast(context, 'Voucher claimed! Find it under My Vouchers.');
    } on Exception catch (e) {
      if (!mounted) return;
      showTopToast(context, 'Could not claim this voucher: $e');
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VoucherCard(
      voucher: widget.voucher,
      pointsBalance: widget.balance,
      isClaiming: _isClaiming,
      onClaim: _claim,
    );
  }
}

class _MyVouchersTab extends ConsumerWidget {
  const _MyVouchersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchers = ref.watch(myVouchersControllerProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myVouchersControllerProvider),
      color: AppColors.ink,
      child: vouchers.when(
        loading: () => const _CenteredSpinner(),
        error: (_, _) => const _CenteredMessage(
          icon: Icons.error_outline_rounded,
          message: "Couldn't load your vouchers.",
        ),
        data: (items) => items.isEmpty
            ? const _CenteredMessage(
                icon: Icons.confirmation_number_outlined,
                message: "You haven't claimed any vouchers yet.",
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, i) =>
                    ClaimedVoucherCard(userVoucher: items[i]),
              ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(transactionsProvider),
      color: AppColors.ink,
      child: transactions.when(
        loading: () => const _CenteredSpinner(),
        error: (_, _) => const _CenteredMessage(
          icon: Icons.error_outline_rounded,
          message: "Couldn't load your history.",
        ),
        data: (items) => items.isEmpty
            ? const _CenteredMessage(
                icon: Icons.receipt_long_outlined,
                message: 'No MapPoints activity yet.',
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, i) =>
                    TransactionTile(transaction: items[i]),
              ),
      ),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [Gap(160), Center(child: CircularProgressIndicator())],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Gap(120),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppColors.text.tertiary),
              const Gap(AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
