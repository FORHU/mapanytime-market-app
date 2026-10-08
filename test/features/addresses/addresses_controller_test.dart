import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/addresses/domain/entities/buyer_address.dart';
import 'package:mapanytime_market_app/features/addresses/presentation/controllers/addresses_controller.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart';

import 'fake_address_server.dart';

void main() {
  ProviderContainer containerFor(FakeAddressServer server, {String? userId}) {
    final container = ProviderContainer(
      overrides: [
        addressRemoteDataSourceProvider.overrideWithValue(server),
        signedInUserIdProvider.overrideWithValue(userId),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  const draft = AddressDraft(
    type: AddressType.office,
    recipientName: 'Juan Dela Cruz',
    phoneNumber: '+639181234567',
    addressLine1: '45 Abanao St, Baguio City',
  );

  test("loads the signed-in buyer's addresses, default first", () async {
    final server = FakeAddressServer([officeAddress, signUpAddress]);
    final c = containerFor(server, userId: 'user-1');

    final list = await c.read(addressesControllerProvider.future);

    expect(list.map((a) => a.id), ['a1', 'a2']);
    expect(c.read(defaultAddressProvider)?.id, 'a1');
  });

  test('signed out: no list and no request', () async {
    final server = FakeAddressServer([signUpAddress]);
    final c = containerFor(server);

    expect(await c.read(addressesControllerProvider.future), isEmpty);
    expect(server.listCalls, 0);
  });

  test('adding reloads from the server, keeping the existing ones', () async {
    final server = FakeAddressServer([signUpAddress]);
    final c = containerFor(server, userId: 'user-1');
    final controller = c.read(addressesControllerProvider.notifier);

    // Before the first load has finished — must not drop the seeded address.
    final ok = await controller.add(draft);

    expect(ok, isTrue);
    final list = c.read(addressesControllerProvider).value!;
    expect(list.map((a) => a.addressLine1), [
      signUpAddress.addressLine1,
      draft.addressLine1,
    ]);
    expect(list.first.isDefault, isTrue);
  });

  test('a repeated address is not duplicated', () async {
    final server = FakeAddressServer([signUpAddress]);
    final c = containerFor(server, userId: 'user-1');
    await c.read(addressesControllerProvider.future);

    await c
        .read(addressesControllerProvider.notifier)
        .add(
          const AddressDraft(
            type: AddressType.home,
            recipientName: 'Juan',
            phoneNumber: '+639171234567',
            addressLine1:
                '123 SESSION RD, BRGY. SESSION ROAD, BAGUIO CITY, BENGUET',
          ),
        );

    expect(c.read(addressesControllerProvider).value, hasLength(1));
  });

  test("set default and delete follow the server's rules", () async {
    final server = FakeAddressServer([signUpAddress, officeAddress]);
    final c = containerFor(server, userId: 'user-1');
    final controller = c.read(addressesControllerProvider.notifier);
    await c.read(addressesControllerProvider.future);

    await controller.setDefault('a2');
    expect(c.read(defaultAddressProvider)?.id, 'a2');

    // Deleting the default promotes the other one.
    await controller.remove('a2');
    final list = c.read(addressesControllerProvider).value!;
    expect(list.map((a) => a.id), ['a1']);
    expect(list.single.isDefault, isTrue);
  });

  test('a failed change reports false and keeps the list', () async {
    final server = FakeAddressServer([signUpAddress])..failWrites = true;
    final c = containerFor(server, userId: 'user-1');
    await c.read(addressesControllerProvider.future);

    final ok = await c.read(addressesControllerProvider.notifier).add(draft);

    expect(ok, isFalse);
    expect(c.read(addressesControllerProvider).value, [signUpAddress]);
  });

  test('displayLine adds optional parts only when they are not already in '
      'the main line', () {
    const withParts = BuyerAddress(
      id: 'x',
      type: AddressType.home,
      recipientName: 'J',
      phoneNumber: '+639171234567',
      addressLine1: '12 Leonard Wood Rd, Baguio City',
      city: 'Baguio City',
      province: 'Benguet',
      isDefault: true,
    );
    expect(withParts.displayLine, '12 Leonard Wood Rd, Baguio City, Benguet');
  });
}
