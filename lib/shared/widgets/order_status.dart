import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Lifecycle of a pickup order. Order matters for the timeline.
enum OrderStatus {
  confirmed,
  preparing,
  ready,
  pickedUp,
  cancelled;

  String get label => switch (this) {
    OrderStatus.confirmed => 'Order Confirmed',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.ready => 'Ready for Pickup',
    OrderStatus.pickedUp => 'Picked Up',
    OrderStatus.cancelled => 'Cancelled',
  };

  IconData get icon => switch (this) {
    OrderStatus.confirmed => Icons.receipt_long_rounded,
    OrderStatus.preparing => Icons.soup_kitchen_rounded,
    OrderStatus.ready => Icons.check_circle_rounded,
    OrderStatus.pickedUp => Icons.shopping_bag_rounded,
    OrderStatus.cancelled => Icons.cancel_rounded,
  };

  Color get color => switch (this) {
    OrderStatus.confirmed => AppColors.ink,
    OrderStatus.preparing => AppColors.status.warning,
    OrderStatus.ready => AppColors.status.success,
    OrderStatus.pickedUp => AppColors.status.success,
    OrderStatus.cancelled => AppColors.status.error,
  };
}
