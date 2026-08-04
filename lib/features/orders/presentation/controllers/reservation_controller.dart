import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/utils/logger.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/orders/data/reservation_remote_datasource.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/inventory_reservation.dart';

final reservationDataSourceProvider = Provider<ReservationRemoteDataSource>((
  ref,
) {
  return ReservationRemoteDataSource(ref.watch(apiServiceProvider));
});

/// The buyer's currently-held stock, refreshed on demand.
final activeReservationsProvider = FutureProvider<List<InventoryReservation>>((
  ref,
) {
  return ref.watch(reservationDataSourceProvider).fetchActive();
});

/// Holds stock while the buyer completes checkout.
///
/// The UI calls [hold] on entering checkout, [confirmAll] once the order id is
/// known, and [releaseAll] if the buyer backs out. State is the list of holds
/// currently owned by this checkout session.
class ReservationController extends AsyncNotifier<List<InventoryReservation>> {
  @override
  Future<List<InventoryReservation>> build() async => const [];

  ReservationRemoteDataSource get _remote =>
      ref.read(reservationDataSourceProvider);

  /// Reserves [quantity] of [inventoryId] and appends the hold to the session.
  Future<InventoryReservation?> hold({
    required String inventoryId,
    required int quantity,
    String? cartId,
  }) async {
    final current = state.value ?? const <InventoryReservation>[];
    try {
      final reservation = await _remote.reserve(
        inventoryId: inventoryId,
        quantity: quantity,
        cartId: cartId,
      );
      state = AsyncValue.data([...current, reservation]);
      return reservation;
    } on Object catch (e, st) {
      // Out-of-stock is an expected outcome, not a crash — surface it to the
      // checkout page without discarding holds already taken.
      appLogger.w('Failed to reserve $inventoryId', error: e);
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Ties every held reservation to [orderId] once the order exists.
  Future<void> confirmAll(String orderId) async {
    final current = state.value ?? const <InventoryReservation>[];
    if (current.isEmpty) return;

    final confirmed = <InventoryReservation>[];
    for (final reservation in current) {
      try {
        confirmed.add(
          await _remote.confirm(
            reservationId: reservation.id,
            orderId: orderId,
          ),
        );
      } on Object catch (e) {
        // The order is already placed; a failed confirm is a server-side
        // reconciliation problem, not something to fail checkout over.
        appLogger.e(
          'Failed to confirm reservation ${reservation.id}',
          error: e,
        );
      }
    }
    state = AsyncValue.data(confirmed);
  }

  /// Releases every held reservation. Called when checkout is abandoned.
  Future<void> releaseAll() async {
    final current = state.value ?? const <InventoryReservation>[];
    for (final reservation in current) {
      try {
        await _remote.release(reservation.id);
      } on Object catch (e) {
        // Expired holds are released server-side anyway.
        appLogger.w(
          'Failed to release reservation ${reservation.id}',
          error: e,
        );
      }
    }
    state = const AsyncValue.data([]);
  }
}

final reservationControllerProvider =
    AsyncNotifierProvider<ReservationController, List<InventoryReservation>>(
      ReservationController.new,
    );
