import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/addresses/domain/entities/buyer_address.dart';

/// The buyer's saved addresses (`/addresses`). The API resolves the buyer
/// from the session, so no user id is ever sent.
class AddressRemoteDataSource {
  const AddressRemoteDataSource(this._api);

  final ApiService _api;

  /// Default first, then newest.
  Future<List<BuyerAddress>> list() async {
    final response = await _api.get(ApiEndpoints.addresses);
    final raw = response is Map && response['data'] is List
        ? response['data'] as List
        : const <dynamic>[];
    return raw
        .map((e) => BuyerAddress.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Adding an address the buyer already has returns that one (no duplicate).
  Future<void> add(AddressDraft draft) =>
      _api.post(ApiEndpoints.addresses, draft.toJson());

  Future<void> update(String id, AddressDraft draft) =>
      _api.patch(ApiEndpoints.address(id), draft.toJson());

  Future<void> setDefault(String id) =>
      _api.post(ApiEndpoints.addressDefault(id));

  Future<void> remove(String id) => _api.delete(ApiEndpoints.address(id));
}
