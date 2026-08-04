import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/return_request.dart';

/// Buyer-side return requests. The backend scopes every call to the caller's
/// buyer profile, so no buyer id is ever sent from the client.
class ReturnRemoteDataSource {
  const ReturnRemoteDataSource(this._api);

  final ApiService _api;

  /// Raises a return against [orderId]. The refund amount is decided server
  /// side from the order total, not supplied here.
  Future<ReturnRequest> requestReturn({
    required String orderId,
    required String reason,
  }) async {
    final response = await _api.post(ApiEndpoints.returns, {
      'orderId': orderId,
      'reason': reason,
    });

    final data = response is Map ? response['data'] : null;
    if (data is! Map) {
      throw const FormatException('Return response had no data object.');
    }
    return _fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ReturnRequest>> fetchMyReturns() async {
    final response = await _api.get(ApiEndpoints.buyerReturns);
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .where((r) => r.id.isNotEmpty)
        .toList();
  }

  ReturnRequest _fromJson(Map<String, dynamic> m) {
    return ReturnRequest(
      id: m['id'] as String? ?? '',
      orderId: m['orderId'] as String? ?? '',
      reason: m['reason'] as String? ?? '',
      status: _statusOf(m['status'] as String?),
      refundAmount: _amountOf(m['refundAmount']),
      requestedAt:
          DateTime.tryParse(m['requestedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// `refundAmount` is a Prisma `Decimal`, which arrives as a JSON string.
  double _amountOf(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  ReturnStatus _statusOf(String? raw) {
    switch (raw) {
      case 'APPROVED':
        return ReturnStatus.approved;
      case 'REJECTED':
        return ReturnStatus.rejected;
      case 'ITEM_RECEIVED':
        return ReturnStatus.itemReceived;
      case 'REFUNDED':
        return ReturnStatus.refunded;
      case 'PENDING':
      default:
        return ReturnStatus.pending;
    }
  }
}
