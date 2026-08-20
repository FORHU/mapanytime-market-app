import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/payments/data/datasources/payment_remote_datasource.dart';
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
  final groups = await ref.watch(paymentProviderGroupsProvider(amount).future);
  return [for (final group in groups) ...group.methods];
});
