import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/shared/widgets/order_status.dart';

class OrderCreationResult {
  const OrderCreationResult({
    required this.orderId,
    this.checkoutUrl,
    this.expiresAt,
  });

  final String orderId;
  final String? checkoutUrl;
  final String? expiresAt;
}

class OrderRemoteDataSource {
  const OrderRemoteDataSource(this._api);

  final ApiService _api;

  Future<OrderCreationResult> createOrder({
    required String type,
    required String pickupAt,
    String? paymentMethodId,
    String? paymentMethod,
    List<String>? productIds,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      'pickupAt': pickupAt,
    };
    if (paymentMethodId != null) {
      payload['paymentMethodId'] = paymentMethodId;
    }
    if (paymentMethod != null) {
      payload['paymentMethod'] = paymentMethod;
    }
    if (productIds != null && productIds.isNotEmpty) {
      payload['productIds'] = productIds;
    }

    final response = await _api.post(ApiEndpoints.ordersCreate, payload);

    final data = response is Map ? response['data'] : null;
    final map = data is Map
        ? data.cast<String, dynamic>()
        : <String, dynamic>{};
    return OrderCreationResult(
      orderId: map['id'] as String? ?? '',
      checkoutUrl: map['checkoutUrl'] as String?,
      expiresAt: map['expiresAt'] as String?,
    );
  }

  Future<List<BuyerOrder>> fetchMyOrders() async {
    final response = await _api.get(ApiEndpoints.ordersCreate);

    var rawList = <dynamic>[];
    if (response is Map) {
      final resData = response['data'];
      if (resData is List) {
        rawList = resData;
      } else if (resData is Map && resData['items'] is List) {
        rawList = resData['items'] as List;
      }
    }

    num parseNum(Object? raw) {
      if (raw is num) return raw;
      if (raw is String) return double.tryParse(raw) ?? 0;
      return 0;
    }

    return rawList.map((json) {
      final map = (json as Map).cast<String, dynamic>();
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

      final rawItems = map['orderitems'] ?? map['orderItems'];
      final items = (rawItems is List ? rawItems : <dynamic>[]).map((i) {
        final iMap = (i as Map).cast<String, dynamic>();
        final pMap = iMap['product'] is Map
            ? (iMap['product'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        return OrderLine(
          name: pMap['name'] as String? ?? 'Unknown Product',
          quantity: (iMap['quantity'] is num)
              ? (iMap['quantity'] as num).toInt()
              : 1,
          price: parseNum(iMap['unitPrice'] ?? iMap['price']),
        );
      }).toList();

      final createdAt = DateTime.tryParse(map['createdAt'] as String? ?? '');
      final completedAt = DateTime.tryParse(
        map['completedAt'] as String? ?? '',
      );

      final rawId = map['id'] as String? ?? '';
      final code = rawId.length >= 8
          ? rawId.substring(0, 8).toUpperCase()
          : rawId.toUpperCase();

      final rawPayments = map['payment'];
      final latestPaymentMethod =
          (rawPayments is List && rawPayments.isNotEmpty)
          ? ((rawPayments.first as Map?)?['paymentMethod'] as Map?)
          : null;
      final isCashOnPickup = latestPaymentMethod?['type'] == 'CASH';

      return BuyerOrder(
        id: rawId,
        code: code,
        storeName:
            (map['store'] as Map?)?['storeName'] as String? ?? 'Unknown Store',
        status: status,
        isCashOnPickup: isCashOnPickup,
        placedLabel: createdAt != null
            ? '${createdAt.month}/${createdAt.day}'
            : '',
        etaLabel: '', // We don't have ETA from backend yet
        lines: items,
        total: parseNum(map['totalAmount'] ?? map['total']),
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

  /// Redeems a seller-shown Cash on Pickup code — the buyer's counterpart of
  /// the seller scanning a buyer's pass for every other payment method.
  /// Throws on a wrong/expired code or if this buyer doesn't own the order;
  /// the server is the only source of truth for whether the code is valid.
  Future<void> confirmCashPickup({
    required String orderId,
    required String code,
  }) {
    return _api.post(ApiEndpoints.cashPickupConfirm, {
      'orderId': orderId,
      'code': code,
    });
  }

  Future<bool> simulateMockPayment(String orderId) async {
    final refNo = 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
    final response = await _api.post('/payments/mock-webhook', {
      'orderId': orderId,
      'status': 'COMPLETED',
      'referenceNumber': refNo,
    });
    return response is Map &&
        (response['success'] == true || response['statusCode'] == 200);
  }
}
