import 'package:intl/intl.dart';

/// App currency formatting. Marketplace is PHP (₱).
class Money {
  Money._();

  static final NumberFormat _peso = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  /// Formats [amount] as `₱1,234.50`.
  static String peso(num amount) => _peso.format(amount);
}
