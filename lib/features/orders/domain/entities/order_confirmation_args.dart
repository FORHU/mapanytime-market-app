import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/payment_method.dart';

/// Everything the confirmation screen needs, handed off directly by the
/// checkout page — avoids a second round-trip for pricing that was already
/// fetched (and guaranteed to match what was just charged) moments earlier.
///
/// Lives in the domain, not beside the page, so checkout can build it without
/// importing another feature's page.
class OrderConfirmationArgs {
  const OrderConfirmationArgs({
    required this.orderId,
    required this.paymentMethodLabel,
    required this.isCashOnDelivery,
    required this.pricing,
    this.selectedMethod,
    this.checkoutUrl,
  });

  final String orderId;
  final String paymentMethodLabel;
  final bool isCashOnDelivery;
  final CartPricing pricing;
  final PaymentMethod? selectedMethod;
  final String? checkoutUrl;
}
