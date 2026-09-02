import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/register_page.dart';
import 'package:mapanytime_market_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _wrap(AuthRepository repository, SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterPage(),
          ),
          GoRoute(
            path: '/register-success',
            builder: (context, state) => const Scaffold(body: Text('Success')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  late MockAuthRepository mockRepository;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockRepository = MockAuthRepository();
  });

  void stubRegisterSuccess() {
    when(
      () => mockRepository.register(
        any(),
        any(),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        middleName: any(named: 'middleName'),
        countryCode: any(named: 'countryCode'),
        roleName: any(named: 'roleName'),
      ),
    ).thenAnswer((_) async => const Right(null));
  }

  // Adding a label above every field made these steps taller than the
  // fixed test viewport, so the primary button can sit below the fold —
  // scroll it into view before tapping, same as a real (scrollable) device.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  Future<void> goToNameStep(WidgetTester tester) async {
    await tester.pumpWidget(_wrap(mockRepository, prefs));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'buyer@example.com',
    );
    await tapVisible(tester, find.text('Next'));
    await tester.pumpAndSettle();
  }

  Future<void> goToPasswordStep(
    WidgetTester tester, {
    String firstName = 'Maria',
    String lastName = 'Cruz',
  }) async {
    await goToNameStep(tester);
    await tester.enterText(find.byKey(const ValueKey('firstName')), firstName);
    await tester.enterText(find.byKey(const ValueKey('lastName')), lastName);
    await tapVisible(tester, find.text('Next'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'blocks advancing past the name step when First or Last Name is empty',
    (tester) async {
      await goToNameStep(tester);

      // Leave First Name blank, fill only Last Name.
      await tester.enterText(find.byKey(const ValueKey('lastName')), 'Cruz');
      await tapVisible(tester, find.text('Next'));
      await tester.pumpAndSettle();

      // Still on the name step — the required-field validator blocked it.
      expect(find.byKey(const ValueKey('firstName')), findsOneWidget);
      expect(find.text('This field is required'), findsOneWidget);
    },
  );

  testWidgets(
    'allows advancing past the name step with Middle Name left blank',
    (tester) async {
      await goToPasswordStep(tester);

      // Reached the password step — Middle Name being empty didn't block it.
      expect(find.byKey(const ValueKey('password')), findsOneWidget);
    },
  );

  testWidgets('blocks submission when Confirm Password does not match', (
    tester,
  ) async {
    stubRegisterSuccess();
    await goToPasswordStep(tester);

    await tester.enterText(
      find.byKey(const ValueKey('password')),
      'a-long-passphrase',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirmPassword')),
      'a-different-passphrase',
    );
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(
      () => mockRepository.register(
        any(),
        any(),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        middleName: any(named: 'middleName'),
        countryCode: any(named: 'countryCode'),
        roleName: any(named: 'roleName'),
      ),
    );
  });

  testWidgets(
    'submits firstName/lastName/middleName from user input on success',
    (tester) async {
      stubRegisterSuccess();
      await goToPasswordStep(tester);

      await tester.enterText(
        find.byKey(const ValueKey('password')),
        'a-long-passphrase',
      );
      await tester.enterText(
        find.byKey(const ValueKey('confirmPassword')),
        'a-long-passphrase',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.register(
          'buyer@example.com',
          'a-long-passphrase',
          firstName: 'Maria',
          lastName: 'Cruz',
          countryCode: any(named: 'countryCode'),
          roleName: 'BUYER',
        ),
      ).called(1);
    },
  );
}
