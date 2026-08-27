import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/rewards/data/datasources/rewards_remote_datasource.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_config.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_transaction.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_voucher.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_wallet.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/user_voucher.dart';

final rewardsRemoteDataSourceProvider = Provider<RewardsRemoteDataSource>(
  (ref) => RewardsRemoteDataSource(ref.watch(apiServiceProvider)),
);

/// The buyer's wallet balance. `AsyncNotifier`, not a plain `FutureProvider` —
/// claiming a voucher or completing an order changes it, so callers need to
/// `ref.invalidate` it.
class WalletController extends AsyncNotifier<RewardWallet> {
  @override
  Future<RewardWallet> build() =>
      ref.read(rewardsRemoteDataSourceProvider).getWallet();
}

final walletControllerProvider =
    AsyncNotifierProvider<WalletController, RewardWallet>(
      WalletController.new,
    );

/// Just the balance, for the profile stats tile and the checkout voucher
/// picker — reads the same cached state as the full wallet.
final mapPointsBalanceProvider = Provider<int>((ref) {
  return ref.watch(walletControllerProvider).value?.balance ?? 0;
});

/// Rarely changes — a plain future is enough, unlike the wallet.
final rewardsConfigProvider = FutureProvider<RewardConfig>((ref) async {
  try {
    return await ref.read(rewardsRemoteDataSourceProvider).getConfig();
  } on Exception {
    return RewardConfig.fallback;
  }
});

/// The active, in-stock voucher catalog. Claiming changes stock, so this is
/// invalidated (not optimistically patched) after a successful claim.
class VoucherCatalogController extends AsyncNotifier<List<RewardVoucher>> {
  @override
  Future<List<RewardVoucher>> build() =>
      ref.read(rewardsRemoteDataSourceProvider).getVoucherCatalog();

  /// Spends points to claim [voucherId]. Throws on failure (insufficient
  /// balance, out of stock) — the caller shows the error.
  Future<void> claim(String voucherId) async {
    await ref.read(rewardsRemoteDataSourceProvider).claimVoucher(voucherId);
    // Three things changed: the wallet balance, this catalog's stock, and
    // the buyer's claimed-voucher list.
    ref
      ..invalidateSelf()
      ..invalidate(walletControllerProvider)
      ..invalidate(myVouchersControllerProvider);
  }
}

final voucherCatalogControllerProvider =
    AsyncNotifierProvider<VoucherCatalogController, List<RewardVoucher>>(
      VoucherCatalogController.new,
    );

/// All of the buyer's claimed vouchers, any status. Fetched once and filtered
/// client-side per tab/checkout use — cheaper than a request per status.
class MyVouchersController extends AsyncNotifier<List<UserVoucher>> {
  @override
  Future<List<UserVoucher>> build() =>
      ref.read(rewardsRemoteDataSourceProvider).getMyVouchers();
}

final myVouchersControllerProvider =
    AsyncNotifierProvider<MyVouchersController, List<UserVoucher>>(
      MyVouchersController.new,
    );

/// Claimed vouchers the buyer can actually use right now — status ACTIVE and
/// not expired. Feeds both the "My Vouchers" tab's active section and the
/// checkout voucher picker.
final usableVouchersProvider = Provider<List<UserVoucher>>((ref) {
  final vouchers = ref.watch(myVouchersControllerProvider).value ?? const [];
  return vouchers.where((v) => v.isUsable).toList();
});

/// One page of the MapPoints ledger, newest first.
final transactionsProvider = FutureProvider<List<RewardTransaction>>((ref) {
  return ref.read(rewardsRemoteDataSourceProvider).getTransactions();
});
