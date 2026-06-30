import 'package:mapanytime_market_app/shared/widgets/order_status.dart';

/// A single line in an order.
class OrderLine {
  const OrderLine({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final num price;

  num get lineTotal => price * quantity;
}

/// A buyer's pickup order. Mock-backed for now.
class BuyerOrder {
  const BuyerOrder({
    required this.id,
    required this.code,
    required this.storeName,
    required this.status,
    required this.placedLabel,
    required this.etaLabel,
    required this.lines,
    required this.total,
    required this.timestamps,
  });

  final String id;
  final String code;
  final String storeName;
  final OrderStatus status;
  final String placedLabel;
  final String etaLabel;
  final List<OrderLine> lines;
  final num total;
  final Map<OrderStatus, String> timestamps;

  bool get isActive => status != OrderStatus.pickedUp;

  int get itemCount => lines.fold<int>(0, (sum, line) => sum + line.quantity);
}
