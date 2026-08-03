enum ReservationStatus {
  reserved,
  consumed,
  expired,
  released,
}

class InventoryReservation {
  const InventoryReservation({
    required this.id,
    required this.inventoryId,
    required this.buyerId,
    this.cartId,
    this.orderId,
    required this.quantity,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String inventoryId;
  final String buyerId;
  final String? cartId;
  final String? orderId;
  final int quantity;
  final ReservationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }
}
