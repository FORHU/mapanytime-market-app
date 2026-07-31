import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/shared/widgets/order_status.dart';

class OrderRemoteDataSource {
  const OrderRemoteDataSource(this._api);

  final ApiService _api;

  Future<String> createOrder({
    required String type,
    required String paymentMethod,
    required String pickupAt,
  }) async {
    final response = await _api.post(ApiEndpoints.ordersCreate, {
      'type': type,
      'paymentMethod': paymentMethod,
      'pickupAt': pickupAt,
    });

    final data = response is Map ? response['data'] : null;
    return (data as Map)['id'] as String;
  }

  Future<List<BuyerOrder>> fetchMyOrders() async {
    final response = await _api.get(ApiEndpoints.ordersCreate);
    final data = response is Map
        ? response['data'] as List<dynamic>
        : <dynamic>[];

    return data.map((json) {
      final map = json as Map<String, dynamic>;
      final statusStr = map['status'] as String? ?? 'PENDING';

      OrderStatus status;
      switch (statusStr) {
        case 'PROCESSING':
        case 'PREPARING':
          status = OrderStatus.preparing;
        case 'READY_FOR_PICKUP':
        case 'READY':
          status = OrderStatus.ready;
        case 'COMPLETED':
        case 'PICKED_UP':
          status = OrderStatus.pickedUp;
        case 'CANCELLED':
        case 'FAILED':
          status = OrderStatus.cancelled;
        case 'PENDING':
        default:
          status = OrderStatus.confirmed;
      }

      final items = (map['orderitems'] as List? ?? []).map((i) {
        final iMap = i as Map<String, dynamic>;
        final pMap = iMap['product'] as Map<String, dynamic>? ?? {};
        return OrderLine(
          name: pMap['name'] as String? ?? 'Unknown Product',
          quantity: iMap['quantity'] as int? ?? 1,
          price: iMap['unitPrice'] as num? ?? 0,
        );
      }).toList();

      final createdAt = DateTime.tryParse(map['createdAt'] as String? ?? '');
      final completedAt = DateTime.tryParse(
        map['completedAt'] as String? ?? '',
      );

      return BuyerOrder(
        id: map['id'] as String,
        code: (map['id'] as String).substring(0, 8).toUpperCase(),
        storeName:
            (map['store'] as Map?)?['storeName'] as String? ?? 'Unknown Store',
        status: status,
        placedLabel: createdAt != null
            ? '${createdAt.month}/${createdAt.day}'
            : '',
        etaLabel: '', // We don't have ETA from backend yet
        lines: items,
        total: map['totalAmount'] as num? ?? 0,
        timestamps: {
          OrderStatus.confirmed: createdAt?.toIso8601String() ?? '',
          if (status == OrderStatus.preparing ||
              status == OrderStatus.ready ||
              status == OrderStatus.pickedUp)
            OrderStatus.preparing: 'Preparing',
          if (status == OrderStatus.ready || status == OrderStatus.pickedUp)
            OrderStatus.ready: 'Ready for Pickup',
          if (completedAt != null)
            OrderStatus.pickedUp: completedAt.toIso8601String(),
        },
      );
    }).toList();
  }

  Future<bool> simulateMockPayment(String orderId) async {
    final refNo = 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
    final response = await _api.post('/payments/mock-webhook', {
      'orderId': orderId,
      'status': 'COMPLETED',
      'referenceNumber': refNo,
    });
    return response is Map && (response['success'] == true || response['statusCode'] == 200);
  }
}
