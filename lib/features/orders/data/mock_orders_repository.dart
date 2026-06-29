import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:mapanytime_market_app/shared/widgets/order_status.dart';

/// Static mock orders — one active, two past. Replace with an API impl later.
class MockOrdersRepository implements OrdersRepository {
  const MockOrdersRepository();

  @override
  Future<List<BuyerOrder>> getOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return const [
      BuyerOrder(
        id: 'o-1024',
        code: 'MA-1024',
        storeName: 'ZenMarket',
        status: OrderStatus.preparing,
        placedLabel: 'Today, 2:14 PM',
        etaLabel: 'Ready in ~8 min',
        total: 595,
        timestamps: {
          OrderStatus.confirmed: '2:14 PM',
          OrderStatus.preparing: '2:16 PM',
        },
        lines: [
          OrderLine(name: 'Fresh Avocados (3pc)', quantity: 1, price: 180),
          OrderLine(name: 'Sourdough Loaf', quantity: 1, price: 240),
          OrderLine(name: 'Greek Yogurt', quantity: 1, price: 130),
        ],
      ),
      BuyerOrder(
        id: 'o-0987',
        code: 'MA-0987',
        storeName: 'Daily Grind',
        status: OrderStatus.pickedUp,
        placedLabel: 'Yesterday, 9:02 AM',
        etaLabel: 'Picked up',
        total: 350,
        timestamps: {
          OrderStatus.confirmed: '9:02 AM',
          OrderStatus.preparing: '9:04 AM',
          OrderStatus.ready: '9:11 AM',
          OrderStatus.pickedUp: '9:20 AM',
        },
        lines: [
          OrderLine(name: 'Cold Brew Tower', quantity: 1, price: 235),
          OrderLine(name: 'Sea Salt Chips', quantity: 1, price: 95),
        ],
      ),
      BuyerOrder(
        id: 'o-0871',
        code: 'MA-0871',
        storeName: 'Nova Home',
        status: OrderStatus.pickedUp,
        placedLabel: 'Jun 22, 4:30 PM',
        etaLabel: 'Picked up',
        total: 1599,
        timestamps: {
          OrderStatus.confirmed: '4:30 PM',
          OrderStatus.preparing: '4:35 PM',
          OrderStatus.ready: '4:50 PM',
          OrderStatus.pickedUp: '5:05 PM',
        },
        lines: [
          OrderLine(name: 'Studio Desk Lamp', quantity: 1, price: 1599),
        ],
      ),
    ];
  }
}
