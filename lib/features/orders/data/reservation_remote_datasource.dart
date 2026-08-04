import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/inventory_reservation.dart';

/// Stock holds taken during checkout so two buyers cannot claim the same unit.
///
/// Lifecycle: [reserve] when the buyer enters checkout, then either [confirm]
/// once the order exists or [release] if they back out. Untouched holds expire
/// server-side after `ttlMinutes` (default 15).
class ReservationRemoteDataSource {
  const ReservationRemoteDataSource(this._api);

  final ApiService _api;

  Future<InventoryReservation> reserve({
    required String inventoryId,
    required int quantity,
    int? ttlMinutes,
    String? cartId,
    String? orderId,
  }) async {
    final response = await _api.post(ApiEndpoints.inventoryReserve, {
      'inventoryId': inventoryId,
      'quantity': quantity,
      'ttlMinutes': ?ttlMinutes,
      'cartId': ?cartId,
      'orderId': ?orderId,
    });

    final data = response is Map ? response['data'] : null;
    if (data is! Map) {
      throw const FormatException('Reservation response had no data object.');
    }
    return _fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<InventoryReservation>> fetchActive() async {
    final response = await _api.get(ApiEndpoints.activeReservations);
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .where((r) => r.id.isNotEmpty)
        .toList();
  }

  /// Consumes the hold, tying it to the placed order.
  Future<InventoryReservation> confirm({
    required String reservationId,
    required String orderId,
  }) async {
    final response = await _api.post(
      ApiEndpoints.reservationConfirm(reservationId),
      {'orderId': orderId},
    );

    final data = response is Map ? response['data'] : null;
    if (data is! Map) {
      throw const FormatException('Confirm response had no data object.');
    }
    return _fromJson(Map<String, dynamic>.from(data));
  }

  /// Returns the held stock. Safe to call on a hold that already expired.
  Future<void> release(String reservationId) async {
    await _api.post(ApiEndpoints.reservationRelease(reservationId));
  }

  InventoryReservation _fromJson(Map<String, dynamic> m) {
    return InventoryReservation(
      id: m['id'] as String? ?? '',
      inventoryId: m['inventoryId'] as String? ?? '',
      buyerId: m['buyerId'] as String? ?? '',
      cartId: m['cartId'] as String?,
      orderId: m['orderId'] as String?,
      quantity: (m['quantity'] as num?)?.toInt() ?? 0,
      status: _statusOf(m['status'] as String?),
      expiresAt:
          DateTime.tryParse(m['expiresAt'] as String? ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  ReservationStatus _statusOf(String? raw) {
    switch (raw) {
      case 'CONSUMED':
        return ReservationStatus.consumed;
      case 'EXPIRED':
        return ReservationStatus.expired;
      case 'RELEASED':
        return ReservationStatus.released;
      case 'RESERVED':
      default:
        return ReservationStatus.reserved;
    }
  }
}
