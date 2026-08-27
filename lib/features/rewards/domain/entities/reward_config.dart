/// Display-safe subset of the active earn-rate config. `GET /rewards/config`.
/// Used to show a client-side "you'll earn ~N points" estimate — the
/// authoritative award only happens server-side when an order completes.
class RewardConfig {
  const RewardConfig({
    required this.earnPercentage,
    required this.pointValueInPhp,
    required this.isEarningActive,
  });

  factory RewardConfig.fromJson(Map<String, dynamic> json) {
    return RewardConfig(
      earnPercentage: (json['earnPercentage'] as num?) ?? 0.001,
      pointValueInPhp: (json['pointValueInPhp'] as num?) ?? 0.1,
      isEarningActive: json['isEarningActive'] as bool? ?? true,
    );
  }

  static const fallback = RewardConfig(
    earnPercentage: 0.001,
    pointValueInPhp: 0.1,
    isEarningActive: true,
  );

  final num earnPercentage;
  final num pointValueInPhp;
  final bool isEarningActive;

  /// Estimated points earned on [eligibleSubtotal] (subtotal minus any
  /// seller discount). Rounds to the nearest point, matching the backend's
  /// award calculation.
  int estimatePoints(num eligibleSubtotal) {
    if (!isEarningActive || pointValueInPhp <= 0) return 0;
    return ((eligibleSubtotal * earnPercentage) / pointValueInPhp).round();
  }
}
