import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/mobility/presentation/driver_tracking_controller.dart';
import 'package:mapanytime_market_app/shared/widgets/category_chip.dart';

/// Driver mode on the map: start/stop broadcasting the assigned vehicle.
/// Renders nothing for anyone without an assigned vehicle.
class DriverTrackingChip extends ConsumerWidget {
  const DriverTrackingChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(myVehicleProvider).value;
    if (vehicle == null) return const SizedBox.shrink();

    final tracking = ref.watch(driverTrackingProvider);

    return CategoryChip(
      label: tracking
          ? 'Sharing ${vehicle.plateNumber} · Stop'
          : 'Start sharing ${vehicle.plateNumber}',
      icon: Icons.directions_bus_rounded,
      selected: tracking,
      onTap: () => unawaited(_toggle(context, ref, tracking: tracking)),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool tracking,
  }) async {
    final controller = ref.read(driverTrackingProvider.notifier);
    if (tracking) return controller.stop();

    final error = await controller.start();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
