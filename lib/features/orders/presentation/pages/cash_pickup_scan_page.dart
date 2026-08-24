import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Cash on Pickup only: the buyer scans the code the seller is showing
/// (see `CashPickupCodeModal` on the web fulfillment terminal) to confirm
/// the order themselves, instead of the seller marking it complete
/// unilaterally. The scanned value is only ever a hint for which order this
/// is about — the server is the sole authority on whether the code itself
/// is correct, current, and unused. See OrderService.confirmCashPickup.
class CashPickupScanPage extends ConsumerStatefulWidget {
  const CashPickupScanPage({required this.order, super.key});

  final BuyerOrder order;

  @override
  ConsumerState<CashPickupScanPage> createState() =>
      _CashPickupScanPageState();
}

class _CashPickupScanPageState extends ConsumerState<CashPickupScanPage> {
  final _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) return;
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    // `MAPANYTIME-CASH-CONFIRM:{orderId}:{code}` — see CashPickupCodeModal
    // on the web seller terminal, the only thing that generates this value.
    final parts = rawValue.split(':');
    if (parts.length != 3 || parts[0] != 'MAPANYTIME-CASH-CONFIRM') {
      return; // Not our QR — keep scanning silently rather than erroring on
      // every unrelated barcode that drifts through the viewfinder.
    }

    final scannedOrderId = parts[1];
    final code = parts[2];

    if (scannedOrderId != widget.order.id) {
      showTopToast(context, 'This code is for a different order.');
      return;
    }

    setState(() => _isProcessing = true);
    unawaited(_controller.stop());

    try {
      await ref
          .read(orderRemoteDataSourceProvider)
          .confirmCashPickup(orderId: widget.order.id, code: code);

      ref.invalidate(ordersProvider);

      if (!mounted) return;
      showTopToast(context, 'Order confirmed — thanks!');
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      showTopToast(context, e.message);
      setState(() => _isProcessing = false);
      unawaited(_controller.start());
    } on Object catch (_) {
      if (!mounted) return;
      showTopToast(context, 'Something went wrong. Try scanning again.');
      setState(() => _isProcessing = false);
      unawaited(_controller.start());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const ModernAppBar(title: 'Confirm Cash Pickup'),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 3,
                      ),
                      borderRadius: AppRadius.brLg,
                    ),
                  ),
                ),
                if (_isProcessing)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.ink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Scan the seller's code",
                  style: TextStyle(
                    color: AppColors.text.onInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Gap(AppSpacing.xs),
                Text(
                  'Ask the seller to show their pickup confirmation code '
                  "once you've handed over payment.",
                  style: TextStyle(
                    color: AppColors.text.onInk.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
