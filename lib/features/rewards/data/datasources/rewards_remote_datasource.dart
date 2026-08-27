import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_config.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_transaction.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_voucher.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_wallet.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/user_voucher.dart';

class RewardsRemoteDataSource {
  const RewardsRemoteDataSource(this._api);

  final ApiService _api;

  Future<RewardWallet> getWallet() async {
    final response = await _api.get(ApiEndpoints.rewardsWallet);
    final data = response is Map ? response['data'] : null;
    return data is Map
        ? RewardWallet.fromJson(data.cast<String, dynamic>())
        : RewardWallet.empty;
  }

  Future<RewardConfig> getConfig() async {
    final response = await _api.get(ApiEndpoints.rewardsConfig);
    final data = response is Map ? response['data'] : null;
    return data is Map
        ? RewardConfig.fromJson(data.cast<String, dynamic>())
        : RewardConfig.fallback;
  }

  Future<List<RewardVoucher>> getVoucherCatalog() async {
    final response = await _api.get(ApiEndpoints.rewardsVouchers);
    final data = response is Map ? response['data'] : null;
    final list = data is List ? data : const <dynamic>[];
    return list
        .map((e) => RewardVoucher.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<UserVoucher> claimVoucher(String voucherId) async {
    final response = await _api.post(
      ApiEndpoints.rewardsVoucherClaim(voucherId),
    );
    final data = response is Map ? response['data'] : null;
    if (data is! Map) {
      throw StateError('Claim voucher: unexpected response shape.');
    }
    return UserVoucher.fromJson(data.cast<String, dynamic>());
  }

  Future<List<UserVoucher>> getMyVouchers({String? status}) async {
    final response = await _api.get(
      ApiEndpoints.rewardsMyVouchers,
      query: status != null ? {'status': status} : null,
    );
    final data = response is Map ? response['data'] : null;
    final list = data is List ? data : const <dynamic>[];
    return list
        .map((e) => UserVoucher.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// One page of the ledger, newest first. No infinite-scroll wiring yet —
  /// [limit] is generous enough that most buyers never need a second page;
  /// add real pagination if that stops being true.
  Future<List<RewardTransaction>> getTransactions({int limit = 50}) async {
    final response = await _api.get(
      ApiEndpoints.rewardsTransactions,
      query: {'limit': limit},
    );
    final data = response is Map ? response['data'] : null;
    final items = data is Map && data['items'] is List
        ? data['items'] as List
        : const <dynamic>[];
    return items
        .map(
          (e) => RewardTransaction.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }
}
