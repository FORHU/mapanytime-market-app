import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/addresses/data/datasources/address_remote_datasource.dart';
import 'package:mapanytime_market_app/features/addresses/domain/entities/buyer_address.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart'
    show signedInUserIdProvider;

final addressRemoteDataSourceProvider = Provider<AddressRemoteDataSource>(
  (ref) => AddressRemoteDataSource(ref.watch(apiServiceProvider)),
);

/// The signed-in buyer's saved addresses, default first. Rebuilds when the
/// account changes, so a new login never sees the previous account's list.
///
/// Changes aren't optimistic: the server owns the rules (one default, the
/// first address is the default, no duplicates), so after each change the
/// list is re-read from it. Each returns whether the change went through.
class AddressesController extends AsyncNotifier<List<BuyerAddress>> {
  @override
  Future<List<BuyerAddress>> build() async {
    if (ref.watch(signedInUserIdProvider) == null) return const [];
    return ref.read(addressRemoteDataSourceProvider).list();
  }

  Future<bool> add(AddressDraft draft) => _change((ds) => ds.add(draft));

  Future<bool> edit(String id, AddressDraft draft) =>
      _change((ds) => ds.update(id, draft));

  Future<bool> setDefault(String id) => _change((ds) => ds.setDefault(id));

  Future<bool> remove(String id) => _change((ds) => ds.remove(id));

  Future<bool> _change(
    Future<void> Function(AddressRemoteDataSource ds) send,
  ) async {
    // Let a first load still in flight finish: setting state during it makes
    // Riverpod drop that load. A failed load is replaced by the reload below.
    try {
      await future;
    } on Object catch (_) {}

    final ds = ref.read(addressRemoteDataSourceProvider);
    try {
      await send(ds);
    } on Exception {
      return false;
    }
    try {
      state = AsyncData(await ds.list());
    } on Exception {
      ref.invalidateSelf();
    }
    return true;
  }
}

final addressesControllerProvider =
    AsyncNotifierProvider<AddressesController, List<BuyerAddress>>(
      AddressesController.new,
    );

/// The default address, if any — e.g. for the Profile summary.
final defaultAddressProvider = Provider<BuyerAddress?>((ref) {
  final list = ref.watch(addressesControllerProvider).value ?? const [];
  for (final a in list) {
    if (a.isDefault) return a;
  }
  return list.isEmpty ? null : list.first;
});
