/// The buyer's MapPoints balance. `GET /rewards/wallet`.
class RewardWallet {
  const RewardWallet({
    required this.balance,
    required this.estimatedValuePhp,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
  });

  factory RewardWallet.fromJson(Map<String, dynamic> json) {
    return RewardWallet(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      estimatedValuePhp: (json['estimatedValuePhp'] as num?) ?? 0,
      lifetimeEarned: (json['lifetimeEarned'] as num?)?.toInt() ?? 0,
      lifetimeSpent: (json['lifetimeSpent'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = RewardWallet(
    balance: 0,
    estimatedValuePhp: 0,
    lifetimeEarned: 0,
    lifetimeSpent: 0,
  );

  final int balance;
  final num estimatedValuePhp;
  final int lifetimeEarned;
  final int lifetimeSpent;
}
