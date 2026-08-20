/// A payment method as the checkout picker needs it, from
/// `GET /payments/methods?amount=`.
///
/// The fee is quoted per method because each bills a different rate (GCash
/// 2.23%, Maya 1.79%, domestic card 3.125% + ₱13.39), and it is grossed up so
/// the platform nets its commission whichever the buyer picks. Never compute a
/// fee on the client — the server is the only place that knows the rate card.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.available,
    this.providerName,
    this.description,
    this.unavailableReason,
    this.feeAmount,
    this.buyerTotalAmount,
  });

  factory PaymentMethod.fromJson(
    Map<String, dynamic> json, {
    String? providerName,
  }) {
    num? parseNum(Object? raw) {
      if (raw is num) return raw;
      if (raw is String) return double.tryParse(raw);
      return null;
    }

    return PaymentMethod(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Payment',
      type: json['type'] as String? ?? 'OTHER',
      available: json['available'] as bool? ?? true,
      providerName: providerName,
      description: json['description'] as String?,
      unavailableReason: json['unavailableReason'] as String?,
      feeAmount: parseNum(json['feeAmount'])?.toDouble(),
      buyerTotalAmount: parseNum(json['buyerTotalAmount'])?.toDouble(),
    );
  }

  final String id;
  final String code;
  final String name;

  /// `PAYMENTMETHODTYPE`. `CASH` is settled at the stall and never touches a
  /// gateway, so it carries no fee and returns no checkout URL.
  final String type;

  final bool available;
  final String? providerName;
  final String? description;

  /// Why this method cannot be used for this basket — a card gated below ₱500,
  /// for instance. Shown to the buyer rather than just greying the row out.
  final String? unavailableReason;

  /// The gateway fee for this basket, already grossed up.
  final double? feeAmount;

  /// Order total plus [feeAmount] — what the buyer actually pays.
  final double? buyerTotalAmount;

  bool get isCash => type.toUpperCase() == 'CASH';
}
