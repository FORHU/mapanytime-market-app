import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/orders/data/mock_orders_repository.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/domain/repositories/orders_repository.dart';

/// The active orders data source. Swap to an API-backed repository here later.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => const MockOrdersRepository(),
);

/// Loads the buyer's orders (mock for now).
final ordersProvider = FutureProvider<List<BuyerOrder>>(
  (ref) => ref.watch(ordersRepositoryProvider).getOrders(),
);
