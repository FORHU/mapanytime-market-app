import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';

/// Source of buyer orders. Swap the implementation (mock → API) without
/// touching the presentation layer.
// ignore: one_member_abstracts
abstract class OrdersRepository {
  Future<List<BuyerOrder>> getOrders();
}
