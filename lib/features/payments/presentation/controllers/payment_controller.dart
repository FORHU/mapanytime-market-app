import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/utils/logger.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/order_payment_status.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/payment_method.dart';

final Provider<PaymentRemoteDataSource> paymentRemoteDataSourceProvider =
    Provider<PaymentRemoteDataSource>((ref) {
      final api = ref.watch(apiServiceProvider);
      return PaymentRemoteDataSource(api);
    });

/// Riverpod family types are complex and self-documenting via generics.
// ignore: specify_nonobvious_property_types
final paymentProviderGroupsProvider =
    FutureProvider.family<List<PaymentProviderGroup>, double>((
      ref,
      amount,
    ) async {
      final dataSource = ref.watch(paymentRemoteDataSourceProvider);
      return dataSource.fetchPaymentMethods(amount: amount > 0 ? amount : null);
    });

/// Riverpod family types are complex and self-documenting via generics.
// ignore: specify_nonobvious_property_types
final paymentMethodsProvider =
    FutureProvider.family<List<PaymentMethod>, double>((ref, amount) async {
      final groups = await ref.watch(
        paymentProviderGroupsProvider(amount).future,
      );
      return [for (final group in groups) ...group.methods];
    });

/// One reading of a payment's status, for a manual "check now".
///
/// Riverpod family types are complex and self-documenting via generics.
// ignore: specify_nonobvious_property_types
final orderPaymentStatusProvider = FutureProvider.autoDispose
    .family<OrderPaymentStatus, String>((
      ref,
      orderId,
    ) async {
      final dataSource = ref.watch(paymentRemoteDataSourceProvider);
      return dataSource.fetchOrderPaymentStatus(orderId);
    });

/// How long to keep asking before leaving the buyer on the pending state.
const Duration _pollBudget = Duration(minutes: 5);

/// Lengthening gaps: the answer usually lands within seconds of the buyer
/// finishing, so ask often at first, then back off rather than hammer the API
/// for five minutes on a payment that was abandoned.
const List<Duration> _pollBackoff = [
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 3),
  Duration(seconds: 5),
  Duration(seconds: 5),
  Duration(seconds: 8),
  Duration(seconds: 10),
];

/// Consecutive network failures tolerated before the error is surfaced. A
/// payment page is exactly where a single dropped request should not be shown
/// to the buyer as "something went wrong".
const int _maxConsecutiveFailures = 5;

/// Polls a payment until it settles, then stops.
///
/// A stream rather than a timer so that closing it *is* the stop condition:
/// returning ends the poll permanently, and `autoDispose` ends it when the
/// buyer leaves the screen. Nothing here writes — the webhook settles the
/// payment server-side, and this only observes the result.
///
/// Riverpod family types are complex and self-documenting via generics.
// ignore: specify_nonobvious_property_types
final paymentStatusPollProvider = StreamProvider.autoDispose
    .family<OrderPaymentStatus, String>((ref, orderId) async* {
      final dataSource = ref.watch(paymentRemoteDataSourceProvider);
      final deadline = DateTime.now().add(_pollBudget);

      var attempt = 0;
      var consecutiveFailures = 0;

      while (true) {
        try {
          final status = await dataSource.fetchOrderPaymentStatus(orderId);
          consecutiveFailures = 0;
          yield status;
          if (status.isSettled) return;
        } on Object catch (error) {
          consecutiveFailures++;
          appLogger.w(
            '[payments] status poll failed for $orderId '
            '($consecutiveFailures/$_maxConsecutiveFailures): $error',
          );
          if (consecutiveFailures >= _maxConsecutiveFailures) rethrow;
        }

        if (DateTime.now().isAfter(deadline)) return;

        final gap = _pollBackoff[attempt.clamp(0, _pollBackoff.length - 1)];
        attempt++;
        await Future<void>.delayed(gap);
      }
    });
