import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/orders/data/order_remote_datasource.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSource(ref.watch(apiServiceProvider));
});

/// Loads the buyer's orders from the backend API.
final ordersProvider = FutureProvider<List<BuyerOrder>>((ref) {
  return ref.watch(orderRemoteDataSourceProvider).fetchMyOrders();
});
