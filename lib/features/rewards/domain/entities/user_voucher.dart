import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_voucher.dart';

enum UserVoucherStatus { active, used, expired }

UserVoucherStatus _statusOf(Object? raw) {
  switch (raw) {
    case 'USED':
      return UserVoucherStatus.used;
    case 'EXPIRED':
      return UserVoucherStatus.expired;
    case 'ACTIVE':
    default:
      return UserVoucherStatus.active;
  }
}

/// A voucher the buyer has claimed. `GET /rewards/my-vouchers`,
/// `POST /rewards/vouchers/<id>/claim`.
class UserVoucher {
  const UserVoucher({
    required this.id,
    required this.voucher,
    required this.status,
    required this.pointsSpent,
    required this.expiresAt,
    this.usedAt,
  });

  factory UserVoucher.fromJson(Map<String, dynamic> json) {
    final voucherJson = (json['voucher'] as Map?)?.cast<String, dynamic>();
    return UserVoucher(
      id: json['id'] as String? ?? '',
      voucher: voucherJson != null
          ? RewardVoucher.fromJson(voucherJson)
          : const RewardVoucher(
              id: '',
              title: 'Voucher',
              pointCost: 0,
              discountType: RewardDiscountType.fixed,
              discountValue: 0,
            ),
      status: _statusOf(json['status']),
      pointsSpent: (json['pointsSpent'] as num?)?.toInt() ?? 0,
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now(),
      usedAt: json['usedAt'] is String
          ? DateTime.tryParse(json['usedAt'] as String)
          : null,
    );
  }

  final String id;
  final RewardVoucher voucher;
  final UserVoucherStatus status;
  final int pointsSpent;
  final DateTime expiresAt;
  final DateTime? usedAt;

  bool get isUsable =>
      status == UserVoucherStatus.active && expiresAt.isAfter(DateTime.now());
}
