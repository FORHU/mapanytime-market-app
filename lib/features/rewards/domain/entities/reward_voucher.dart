enum RewardDiscountType { fixed, percentage }

RewardDiscountType _discountTypeOf(Object? raw) => raw == 'PERCENTAGE'
    ? RewardDiscountType.percentage
    : RewardDiscountType.fixed;

/// Prisma `Decimal` columns (discountValue, minOrderAmount,
/// maxDiscountAmount) serialize as JSON strings, not numbers.
num? _numOf(Object? raw) {
  if (raw is num) return raw;
  if (raw is String) return num.tryParse(raw);
  return null;
}

/// A voucher in the claimable catalog. `GET /rewards/vouchers`.
class RewardVoucher {
  const RewardVoucher({
    required this.id,
    required this.title,
    required this.pointCost,
    required this.discountType,
    required this.discountValue,
    this.description,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.validityDays = 30,
  });

  factory RewardVoucher.fromJson(Map<String, dynamic> json) {
    return RewardVoucher(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Voucher',
      description: json['description'] as String?,
      pointCost: (json['pointCost'] as num?)?.toInt() ?? 0,
      discountType: _discountTypeOf(json['discountType']),
      discountValue: _numOf(json['discountValue']) ?? 0,
      minOrderAmount: _numOf(json['minOrderAmount']),
      maxDiscountAmount: _numOf(json['maxDiscountAmount']),
      validityDays: (json['validityDays'] as num?)?.toInt() ?? 30,
    );
  }

  final String id;
  final String title;
  final String? description;
  final int pointCost;
  final RewardDiscountType discountType;
  final num discountValue;
  final num? minOrderAmount;
  final num? maxDiscountAmount;
  final int validityDays;

  /// Estimated discount against [eligibleSubtotal] — the same formula the
  /// backend applies in `RewardService.validateVoucherForOrder`. The order
  /// response is the source of truth; this is only a checkout-time preview.
  num estimateDiscount(num eligibleSubtotal) {
    var amount = discountType == RewardDiscountType.fixed
        ? discountValue
        : eligibleSubtotal * (discountValue / 100);
    if (maxDiscountAmount != null && amount > maxDiscountAmount!) {
      amount = maxDiscountAmount!;
    }
    if (amount > eligibleSubtotal) amount = eligibleSubtotal;
    return amount < 0 ? 0 : amount;
  }

  /// Whether [eligibleSubtotal] clears this voucher's minimum spend.
  bool meetsMinimum(num eligibleSubtotal) =>
      minOrderAmount == null || eligibleSubtotal >= minOrderAmount!;
}
