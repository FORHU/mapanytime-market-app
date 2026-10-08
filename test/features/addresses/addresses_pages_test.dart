import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/addresses/domain/entities/buyer_address.dart';
import 'package:mapanytime_market_app/features/addresses/presentation/controllers/addresses_controller.dart';
import 'package:mapanytime_market_app/features/addresses/presentation/pages/address_form_page.dart';
import 'package:mapanytime_market_app/features/addresses/presentation/pages/addresses_page.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/user_entity.dart';
import 'package:mapanytime_market_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart';
import 'package:mapanytime_market_app/l10n/generated/app_localizations.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';

import 'fake_address_server.dart';

Widget _app(FakeAddressServer server) => ProviderScope(
  overrides: [
    addressRemoteDataSourceProvider.overrideWithValue(server),
    signedInUserIdProvider.overrideWithValue('user-1'),
    profileProvider.overrideWithValue(
      const UserEntity(
        id: 'user-1',
        email: 'juan@example.com',
        name: 'Juan Dela Cruz',
      ),
    ),
  ],
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: RouteNames.addresses,
      routes: [
        GoRoute(
          path: RouteNames.addresses,
          builder: (context, state) => const AddressesPage(),
        ),
        GoRoute(
          path: RouteNames.addressForm,
          builder: (context, state) =>
              AddressFormPage(initial: state.extra as BuyerAddress?),
        ),
      ],
    ),
  ),
);

void main() {
  /// Lets any top toast run its 3 s timer and slide away.
  Future<void> drainToasts(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String id, String item) async {
    await tester.tap(find.byKey(ValueKey('addressMenu-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the sign-up address as the default', (tester) async {
    await tester.pumpWidget(_app(FakeAddressServer([signUpAddress])));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text(signUpAddress.addressLine1), findsOneWidget);
    expect(
      find.text('Juan Santos Dela Cruz · +63 917 123 4567'),
      findsOneWidget,
    );
  });

  testWidgets('empty: explains and offers to add the first address', (
    tester,
  ) async {
    final server = FakeAddressServer();
    await tester.pumpWidget(_app(server));
    await tester.pumpAndSettle();

    expect(find.text('No saved addresses'), findsOneWidget);
    await tester.tap(find.text('Add address'));
    await tester.pumpAndSettle();

    // The account's name is filled in; the first address is the default.
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('recipientName')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'Juan Dela Cruz',
    );
    expect(find.text('Your first address is your default.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('addressPhone')),
      '9171234567',
    );
    await tester.enterText(
      find.byKey(const ValueKey('addressLine')),
      '45 Abanao St, Baguio City',
    );
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    expect(server.rows.single.addressLine1, '45 Abanao St, Baguio City');
    expect(server.rows.single.phoneNumber, '+639171234567');
    expect(find.text('No saved addresses'), findsNothing);
    expect(find.text('Default'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('the form needs an address and a PH mobile number', (
    tester,
  ) async {
    final server = FakeAddressServer([signUpAddress]);
    await tester.pumpWidget(_app(server));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add address'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('addressPhone')), '1234');
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget); // address
    expect(
      find.text('Use a PH mobile number, like 917 123 4567'),
      findsOneWidget,
    );
    expect(server.rows, hasLength(1));
  });

  testWidgets('edit opens prefilled and saves the change', (tester) async {
    final server = FakeAddressServer([signUpAddress]);
    await tester.pumpWidget(_app(server));
    await tester.pumpAndSettle();

    await openMenu(tester, 'a1', 'Edit');
    expect(find.text('Edit address'), findsOneWidget);
    expect(find.text(signUpAddress.addressLine1), findsOneWidget);
    // The phone sits after the +63 prefix.
    expect(find.text('9171234567'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('addressLine')),
      '12 Leonard Wood Rd, Baguio City',
    );
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    expect(server.rows.single.addressLine1, '12 Leonard Wood Rd, Baguio City');
    expect(find.text('12 Leonard Wood Rd, Baguio City'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('set as default moves the badge', (tester) async {
    await tester.pumpWidget(
      _app(FakeAddressServer([signUpAddress, officeAddress])),
    );
    await tester.pumpAndSettle();

    await openMenu(tester, 'a2', 'Set as default');

    final officeCard = find.byKey(const ValueKey('address-a2'));
    expect(
      find.descendant(of: officeCard, matching: find.text('Default')),
      findsOneWidget,
    );
    expect(find.text('Default'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('delete asks first; cancel keeps, confirm removes', (
    tester,
  ) async {
    final server = FakeAddressServer([signUpAddress, officeAddress]);
    await tester.pumpWidget(_app(server));
    await tester.pumpAndSettle();

    await openMenu(tester, 'a2', 'Delete');
    expect(find.text('Delete this address?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(server.rows, hasLength(2));

    await openMenu(tester, 'a2', 'Delete');
    await tester.tap(find.byKey(const ValueKey('confirmDeleteAddress')));
    await tester.pumpAndSettle();

    expect(server.rows.map((a) => a.id), ['a1']);
    expect(find.text(officeAddress.addressLine1), findsNothing);
    await drainToasts(tester);
  });
}
