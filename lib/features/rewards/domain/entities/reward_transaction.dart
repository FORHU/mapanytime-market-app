/// One row of the MapPoints ledger. `GET /rewards/transactions`.
class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.description,
  });

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'ADJUSTMENT',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      description: json['description'] as String?,
    );
  }

  /// EARN | SPEND | BONUS | REFUND | EXPIRED | REVERSAL | ADJUSTMENT.
  final String type;
  final String id;
  final int amount;
  final int balanceAfter;
  final DateTime createdAt;
  final String? description;
}
