import 'package:mapanytime_market_app/features/addresses/data/datasources/address_remote_datasource.dart';
import 'package:mapanytime_market_app/features/addresses/domain/entities/buyer_address.dart';

/// In-memory stand-in for `/addresses` that applies the API's rules: the
/// first address is the default, one default at a time, deleting the default
/// promotes the newest remaining one, and a repeated address isn't duplicated.
class FakeAddressServer implements AddressRemoteDataSource {
  FakeAddressServer([List<BuyerAddress> seed = const []]) : _rows = [...seed];

  final List<BuyerAddress> _rows;
  var _nextId = 100;
  bool failWrites = false;
  int listCalls = 0;

  List<BuyerAddress> get rows => List.unmodifiable(_rows);

  @override
  Future<List<BuyerAddress>> list() async {
    listCalls++;
    final sorted = [..._rows]
      ..sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
    return sorted;
  }

  BuyerAddress _copy(BuyerAddress a, {bool? isDefault, AddressDraft? draft}) =>
      BuyerAddress(
        id: a.id,
        type: draft?.type ?? a.type,
        recipientName: draft?.recipientName ?? a.recipientName,
        phoneNumber: draft?.phoneNumber ?? a.phoneNumber,
        addressLine1: draft?.addressLine1 ?? a.addressLine1,
        isDefault: isDefault ?? a.isDefault,
      );

  void _clearDefault() {
    for (var i = 0; i < _rows.length; i++) {
      _rows[i] = _copy(_rows[i], isDefault: false);
    }
  }

  @override
  Future<void> add(AddressDraft draft) async {
    if (failWrites) throw Exception('500');
    final line = draft.addressLine1.trim().toLowerCase();
    if (_rows.any((a) => a.addressLine1.trim().toLowerCase() == line)) return;
    final isDefault = _rows.isEmpty || draft.isDefault;
    if (isDefault) _clearDefault();
    _rows.add(
      BuyerAddress(
        id: 'a${_nextId++}',
        type: draft.type,
        recipientName: draft.recipientName,
        phoneNumber: draft.phoneNumber,
        addressLine1: draft.addressLine1,
        isDefault: isDefault,
      ),
    );
  }

  @override
  Future<void> update(String id, AddressDraft draft) async {
    if (failWrites) throw Exception('500');
    final i = _rows.indexWhere((a) => a.id == id);
    if (draft.isDefault) _clearDefault();
    _rows[i] = _copy(
      _rows[i],
      draft: draft,
      isDefault: draft.isDefault ? true : null,
    );
  }

  @override
  Future<void> setDefault(String id) async {
    if (failWrites) throw Exception('500');
    _clearDefault();
    final i = _rows.indexWhere((a) => a.id == id);
    _rows[i] = _copy(_rows[i], isDefault: true);
  }

  @override
  Future<void> remove(String id) async {
    if (failWrites) throw Exception('500');
    final removed = _rows.firstWhere((a) => a.id == id);
    _rows.remove(removed);
    if (removed.isDefault && _rows.isNotEmpty) {
      _rows[_rows.length - 1] = _copy(_rows.last, isDefault: true);
    }
  }
}

const signUpAddress = BuyerAddress(
  id: 'a1',
  type: AddressType.home,
  recipientName: 'Juan Santos Dela Cruz',
  phoneNumber: '+639171234567',
  addressLine1: '123 Session Rd, Brgy. Session Road, Baguio City, Benguet',
  isDefault: true,
);

const officeAddress = BuyerAddress(
  id: 'a2',
  type: AddressType.office,
  recipientName: 'Juan Dela Cruz',
  phoneNumber: '+639181234567',
  addressLine1: '45 Abanao St, Baguio City',
  isDefault: false,
);
