import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/orders/data/return_remote_datasource.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/return_request.dart';

final returnDataSourceProvider = Provider<ReturnRemoteDataSource>((ref) {
  return ReturnRemoteDataSource(ref.watch(apiServiceProvider));
});

/// The buyer's return requests, keyed by order id for quick lookup from the
/// order-history rows.
final returnsByOrderProvider = FutureProvider<Map<String, ReturnRequest>>((
  ref,
) async {
  final requests = await ref.watch(returnsControllerProvider.future);
  return {for (final r in requests) r.orderId: r};
});

/// Loads the buyer's returns and submits new ones.
class ReturnsController extends AsyncNotifier<List<ReturnRequest>> {
  @override
  Future<List<ReturnRequest>> build() {
    return ref.watch(returnDataSourceProvider).fetchMyReturns();
  }

  /// Submits a return for [orderId]. Returns `null` when the request was
  /// rejected (already returned, not the buyer's order, order not found), with
  /// the failure surfaced through the async error channel.
  Future<ReturnRequest?> requestReturn({
    required String orderId,
    required String reason,
  }) async {
    final current = state.value ?? const <ReturnRequest>[];
    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(returnDataSourceProvider)
          .requestReturn(orderId: orderId, reason: reason);
      state = AsyncValue.data([created, ...current]);
      return created;
    } on Object catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Re-reads the list after a seller-side status change.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(returnDataSourceProvider).fetchMyReturns(),
    );
  }
}

final returnsControllerProvider =
    AsyncNotifierProvider<ReturnsController, List<ReturnRequest>>(
      ReturnsController.new,
    );
