import 'package:equatable/equatable.dart';

/// Lifecycle of a buyer's return request, mirroring the backend `RETURNSTATUS`.
enum ReturnStatus { pending, approved, rejected, itemReceived, refunded }

extension ReturnStatusX on ReturnStatus {
  /// Short label for the order-history badge.
  String get label => switch (this) {
    ReturnStatus.pending => 'Return requested',
    ReturnStatus.approved => 'Return approved',
    ReturnStatus.rejected => 'Return rejected',
    ReturnStatus.itemReceived => 'Item received',
    ReturnStatus.refunded => 'Refunded',
  };

  /// Whether the request has reached a terminal state.
  bool get isClosed =>
      this == ReturnStatus.rejected || this == ReturnStatus.refunded;
}

/// A return request raised by the buyer against one of their orders.
class ReturnRequest extends Equatable {
  const ReturnRequest({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.status,
    required this.refundAmount,
    required this.requestedAt,
  });

  final String id;
  final String orderId;
  final String reason;
  final ReturnStatus status;
  final double refundAmount;
  final DateTime requestedAt;

  @override
  List<Object?> get props => [
    id,
    orderId,
    reason,
    status,
    refundAmount,
    requestedAt,
  ];
}
