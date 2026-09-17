/// Where a payment actually stands, from
/// `GET /payments/orders/<orderId>/payment`.
///
/// This is the only trustworthy answer to "did it pay?". The gateway hands the
/// buyer's browser back to us the moment they tap through, which normally beats
/// the webhook that settles the payment — so an order reads `PENDING` for a few
/// seconds after a perfectly good payment, and reads `PENDING` forever after an
/// abandoned one. Neither the redirect nor the fact that checkout was launched
/// tells us which happened; only this does.
library;

/// `PAYMENTSTATUS` on the server.
enum PaymentStatusValue {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  expired,
  unknown;

  static PaymentStatusValue fromApi(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PENDING':
        return PaymentStatusValue.pending;
      case 'PROCESSING':
        return PaymentStatusValue.processing;
      case 'COMPLETED':
        return PaymentStatusValue.completed;
      case 'FAILED':
        return PaymentStatusValue.failed;
      case 'CANCELLED':
      case 'CANCELED':
        return PaymentStatusValue.cancelled;
      case 'REFUNDED':
        return PaymentStatusValue.refunded;
      case 'EXPIRED':
        return PaymentStatusValue.expired;
      default:
        return PaymentStatusValue.unknown;
    }
  }
}

/// What the confirmation screen renders.
enum PaymentOutcome { paid, waiting, failed, cancelled }

class OrderPaymentStatus {
  const OrderPaymentStatus({
    required this.orderId,
    required this.paymentStatus,
    required this.orderStatus,
    this.paymentId,
    this.amount,
    this.currency,
    this.provider,
    this.paymentMethod,
    this.paidAt,
  });

  factory OrderPaymentStatus.fromJson(Map<String, dynamic> json) {
    num? parseNum(Object? raw) {
      if (raw is num) return raw;
      if (raw is String) return double.tryParse(raw);
      return null;
    }

    return OrderPaymentStatus(
      orderId: json['orderId'] as String? ?? '',
      paymentStatus: PaymentStatusValue.fromApi(
        json['paymentStatus'] as String?,
      ),
      orderStatus: (json['orderStatus'] as String? ?? '').toUpperCase(),
      paymentId: json['paymentId'] as String?,
      amount: parseNum(json['amount'])?.toDouble(),
      currency: json['currency'] as String?,
      provider: json['provider'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
    );
  }

  final String orderId;
  final PaymentStatusValue paymentStatus;

  /// The order's own status. Carries the only failure signal that ever arrives
  /// for an abandoned payment — see [outcome].
  final String orderStatus;

  final String? paymentId;
  final double? amount;
  final String? currency;
  final String? provider;
  final String? paymentMethod;
  final DateTime? paidAt;

  /// True once nothing further will change on its own, which is what stops the
  /// poll. Mirrors the server's terminal set.
  bool get isSettled =>
      const {
        PaymentStatusValue.completed,
        PaymentStatusValue.failed,
        PaymentStatusValue.cancelled,
        PaymentStatusValue.refunded,
        PaymentStatusValue.expired,
      }.contains(paymentStatus) ||
      const {'COMPLETED', 'CANCELLED', 'FAILED'}.contains(orderStatus);

  /// How the payment should be presented.
  ///
  /// The order status is consulted as well as the payment status because the
  /// backend emits a socket notification only on success — an expired or
  /// abandoned session produces no push at all, and the order being moved to
  /// FAILED is the only trace of it we ever see.
  PaymentOutcome get outcome {
    switch (paymentStatus) {
      case PaymentStatusValue.completed:
        return PaymentOutcome.paid;
      case PaymentStatusValue.failed:
      case PaymentStatusValue.expired:
        return PaymentOutcome.failed;
      case PaymentStatusValue.cancelled:
      case PaymentStatusValue.refunded:
        return PaymentOutcome.cancelled;
      case PaymentStatusValue.pending:
      case PaymentStatusValue.processing:
      case PaymentStatusValue.unknown:
        break;
    }

    // A cash order settles at the stall, so it reaches COMPLETED without the
    // payment row ever leaving PENDING.
    if (orderStatus == 'COMPLETED') return PaymentOutcome.paid;
    if (orderStatus == 'FAILED') return PaymentOutcome.failed;
    if (orderStatus == 'CANCELLED') return PaymentOutcome.cancelled;

    return PaymentOutcome.waiting;
  }
}
