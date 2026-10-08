import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_scanner.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_text_parser.dart';
import 'package:mapanytime_market_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/register_page.dart';
import 'package:mapanytime_market_app/l10n/generated/app_localizations.dart';
import 'package:mapanytime_market_app/shared/widgets/back_chevron_button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class _FakePicker implements IdPhotoPicker {
  String? path = '/photos/id.jpg';
  PlatformException? error;
  final sources = <ImageSource>[];

  @override
  Future<String?> pick(ImageSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return path;
  }
}

class _FakeScanner implements IdScanner {
  ScannedId result = _philsys;

  /// When set, reading waits for it — to observe the "Reading" state.
  Completer<void>? gate;

  /// When set, reading fails with it.
  Exception? error;

  @override
  Future<ScannedId> scan(String imagePath) async {
    await gate?.future;
    if (error != null) throw error!;
    return result;
  }
}

final _philsys = ScannedId(
  idType: IdType.philsys,
  firstName: 'Juan',
  lastName: 'Dela Cruz',
  dateOfBirth: DateTime(1994, 3, 15),
  sex: Sex.male,
  address: '123 Session Rd, Brgy. Session Road, Baguio City, Benguet',
  idNumber: '1234-5678-9012-3456',
  unsure: const {IdField.address},
);

Widget _wrap(
  AuthRepository repository,
  SharedPreferences prefs,
  _FakePicker picker,
  _FakeScanner scanner,
) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      sharedPreferencesProvider.overrideWithValue(prefs),
      idPhotoPickerProvider.overrideWithValue(picker),
      idScannerProvider.overrideWithValue(scanner),
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
  late _FakePicker picker;
  late _FakeScanner scanner;

  setUpAll(() {
    registerFallbackValue(
      RegistrationProfile(
        phoneNumber: '',
        dateOfBirth: DateTime(2000),
        address: '',
        idType: IdType.philsys,
        idNumber: '',
        idPhotoPath: '',
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockRepository = MockAuthRepository();
    picker = _FakePicker();
    scanner = _FakeScanner();
  });

  Future<Either<Failure, void>> registerCall() => mockRepository.register(
    any(),
    any(),
    firstName: any(named: 'firstName'),
    lastName: any(named: 'lastName'),
    middleName: any(named: 'middleName'),
    countryCode: any(named: 'countryCode'),
    roleName: any(named: 'roleName'),
    profile: any(named: 'profile'),
  );

  void stubRegisterSuccess() =>
      when(registerCall).thenAnswer((_) async => const Right(null));

  // The steps are taller than the fixed test viewport, so scroll a control
  // into view before using it, same as on a real (scrollable) device.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterVisible(
    WidgetTester tester,
    String fieldKey,
    String text,
  ) async {
    final finder = find.byKey(ValueKey(fieldKey));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Current text of the field keyed [fieldKey] (hint text excluded).
  String fieldText(WidgetTester tester, String fieldKey) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(ValueKey(fieldKey)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  /// Lets any top toast run its 3 s timer and slide away.
  Future<void> drainToasts(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  const unreadable =
      "We couldn't read this photo. Retake it with the whole ID in the "
      'frame, in focus and without glare.';
  const notAnId =
      "This doesn't look like an accepted ID. Use one of the IDs listed "
      'below.';
  const mismatch =
      'The name on your ID does not match the name you entered. Please '
      'double-check your information and make sure your name is the same as '
      'the name on the ID you uploaded.';

  /// Fills the account step. Defaults are the name on [_philsys].
  Future<void> fillAccount(
    WidgetTester tester, {
    String first = 'Juan',
    String middle = 'Santos',
    String last = 'Dela Cruz',
    String phone = '917 123 4567',
  }) async {
    await enterVisible(tester, 'email', 'buyer@example.com');
    await enterVisible(tester, 'firstName', first);
    await enterVisible(tester, 'middleName', middle);
    await enterVisible(tester, 'lastName', last);
    await enterVisible(tester, 'phone', phone);
  }

  Future<void> goToIdStep(
    WidgetTester tester, {
    String first = 'Juan',
    String last = 'Dela Cruz',
  }) async {
    await tester.pumpWidget(_wrap(mockRepository, prefs, picker, scanner));
    await tester.pumpAndSettle();
    await fillAccount(tester, first: first, last: last);
    await tapVisible(tester, find.text('Next'));
    expect(find.text('Upload a valid ID'), findsOneWidget);
  }

  Future<void> pickFromGallery(WidgetTester tester) =>
      tapVisible(tester, find.byKey(const ValueKey('chooseIdPhoto')));

  Future<void> goToReviewStep(WidgetTester tester) async {
    await goToIdStep(tester);
    await pickFromGallery(tester);
    expect(find.text('Check your details'), findsOneWidget);
  }

  Future<void> goToPasswordStep(WidgetTester tester) async {
    await goToReviewStep(tester);
    await tapVisible(tester, find.text('Looks good, continue'));
    expect(find.byKey(const ValueKey('password')), findsOneWidget);
  }

  group('account step', () {
    testWidgets('asks for email, name and phone number', (tester) async {
      await tester.pumpWidget(_wrap(mockRepository, prefs, picker, scanner));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      for (final key in [
        'email',
        'firstName',
        'middleName',
        'lastName',
        'phone',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
    });

    testWidgets('requires first name, last name and phone number', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(mockRepository, prefs, picker, scanner));
      await tester.pumpAndSettle();
      await enterVisible(tester, 'email', 'buyer@example.com');

      await tapVisible(tester, find.text('Next'));

      expect(find.text('Create your account'), findsOneWidget);
      // First name, last name and phone; middle name is optional.
      expect(find.text('This field is required'), findsNWidgets(3));
    });

    testWidgets('rejects a phone number that is not a PH mobile', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(mockRepository, prefs, picker, scanner));
      await tester.pumpAndSettle();
      await fillAccount(tester, phone: '1234');

      await tapVisible(tester, find.text('Next'));

      expect(
        find.text('Use a PH mobile number, like 917 123 4567'),
        findsOneWidget,
      );
      expect(find.text('Upload a valid ID'), findsNothing);
    });

    testWidgets('middle name is optional', (tester) async {
      await tester.pumpWidget(_wrap(mockRepository, prefs, picker, scanner));
      await tester.pumpAndSettle();
      await fillAccount(tester, middle: '');

      await tapVisible(tester, find.text('Next'));

      expect(find.text('Upload a valid ID'), findsOneWidget);
    });
  });

  group('name check against the ID', () {
    testWidgets('a matching ID moves on to the review step', (tester) async {
      // Typed differently from the ID: case, spacing.
      await goToIdStep(tester, first: 'juan', last: 'De la Cruz');
      await pickFromGallery(tester);

      expect(find.text('Check your details'), findsOneWidget);
      expect(find.text(mismatch), findsNothing);
    });

    testWidgets('a mismatching ID is refused with the exact message', (
      tester,
    ) async {
      await goToIdStep(tester, first: 'Pedro', last: 'Santos');
      await pickFromGallery(tester);

      expect(find.text('Upload a valid ID'), findsOneWidget);
      expect(find.text(mismatch), findsOneWidget);
      expect(find.text('Check your details'), findsNothing);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('"Edit your name" goes back with the values kept, and a '
        'corrected name passes', (tester) async {
      await goToIdStep(tester, first: 'Pedro');
      await pickFromGallery(tester);
      expect(find.text(mismatch), findsOneWidget);

      await tapVisible(tester, find.text('Edit your name'));
      expect(find.text('Create your account'), findsOneWidget);
      expect(fieldText(tester, 'firstName'), 'Pedro');
      expect(fieldText(tester, 'lastName'), 'Dela Cruz');
      expect(fieldText(tester, 'phone'), '917 123 4567');

      await enterVisible(tester, 'firstName', 'Juan');
      await tapVisible(tester, find.text('Next'));
      // The old mismatch is about a name that no longer exists.
      expect(find.text(mismatch), findsNothing);

      await pickFromGallery(tester);
      expect(find.text('Check your details'), findsOneWidget);
    });

    testWidgets('renaming after an accepted ID asks for the ID again', (
      tester,
    ) async {
      await goToReviewStep(tester);
      // Back to the account step and change the surname.
      await tapVisible(tester, find.byType(BackChevronButton));
      await tapVisible(tester, find.byType(BackChevronButton));
      expect(find.text('Create your account'), findsOneWidget);
      await enterVisible(tester, 'lastName', 'Santos');
      await tapVisible(tester, find.text('Next'));

      expect(find.text('Upload a valid ID'), findsOneWidget);
      expect(find.text(mismatch), findsOneWidget);
      // The accepted ID no longer counts.
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('editing the name in a way that still matches keeps the ID', (
      tester,
    ) async {
      await goToReviewStep(tester);
      await tapVisible(tester, find.byType(BackChevronButton));
      await tapVisible(tester, find.byType(BackChevronButton));
      await enterVisible(tester, 'lastName', 'DELA CRUZ');
      await tapVisible(tester, find.text('Next'));

      expect(find.text(mismatch), findsNothing);
      await tapVisible(tester, find.text('Next'));
      expect(find.text('Check your details'), findsOneWidget);
    });
  });

  testWidgets('the review step fills in the ID details', (tester) async {
    await goToReviewStep(tester);

    expect(picker.sources, [ImageSource.gallery]);
    expect(fieldText(tester, 'dateOfBirth'), 'Mar 15, 1994');
    expect(
      fieldText(tester, 'address'),
      '123 Session Rd, Brgy. Session Road, Baguio City, Benguet',
    );
    expect(fieldText(tester, 'idNumber'), '1234-5678-9012-3456');
    expect(find.text('Check this'), findsOneWidget); // unsure address
    expect(find.text('From ID'), findsWidgets);
    expect(find.text('Edited'), findsNothing);
  });

  group('names on the review step', () {
    testWidgets('show what was entered, not what the ID says', (tester) async {
      // Typed differently from the ID ("Juan" / "Dela Cruz") but matching.
      await goToIdStep(tester, first: 'juan', last: 'De la Cruz');
      await pickFromGallery(tester);

      expect(find.text('Check your details'), findsOneWidget);
      expect(fieldText(tester, 'firstName'), 'juan');
      expect(fieldText(tester, 'lastName'), 'De la Cruz');
      // The middle name stays on the account step only.
      expect(find.byKey(const ValueKey('middleName')), findsNothing);
      expect(find.text('Middle name (optional)'), findsNothing);
    });

    testWidgets('an edit is the same value as on the account step', (
      tester,
    ) async {
      await goToReviewStep(tester);
      await enterVisible(tester, 'lastName', 'DELA CRUZ');

      await tapVisible(tester, find.byType(BackChevronButton));
      await tapVisible(tester, find.byType(BackChevronButton));

      expect(find.text('Create your account'), findsOneWidget);
      expect(fieldText(tester, 'lastName'), 'DELA CRUZ');
      // The middle name typed there is untouched.
      expect(fieldText(tester, 'middleName'), 'Santos');
    });

    testWidgets('a name that no longer matches the ID blocks Continue', (
      tester,
    ) async {
      await goToReviewStep(tester);
      await enterVisible(tester, 'lastName', 'Santos');

      await tapVisible(tester, find.text('Looks good, continue'));

      expect(find.text('Check your details'), findsOneWidget);
      expect(find.text(mismatch), findsOneWidget);
      expect(find.byKey(const ValueKey('password')), findsNothing);
      await drainToasts(tester);

      // Put back (in other casing) and it goes through.
      await enterVisible(tester, 'lastName', 'DELA CRUZ');
      await tapVisible(tester, find.text('Looks good, continue'));
      expect(find.byKey(const ValueKey('password')), findsOneWidget);
    });

    testWidgets('an emptied name is required', (tester) async {
      await goToReviewStep(tester);
      await enterVisible(tester, 'firstName', '');

      await tapVisible(tester, find.text('Looks good, continue'));

      expect(find.text('Check your details'), findsOneWidget);
      expect(find.text('This field is required'), findsOneWidget);
      await drainToasts(tester);
    });
  });

  testWidgets('shows the photo being read before moving on', (tester) async {
    scanner.gate = Completer<void>();
    await goToIdStep(tester);
    final camera = find.byKey(const ValueKey('takeIdPhoto'));
    await tester.ensureVisible(camera);
    await tester.pumpAndSettle();
    await tester.tap(camera);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(picker.sources, [ImageSource.camera]);
    expect(find.text('Reading your ID…'), findsOneWidget);

    scanner.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Check your details'), findsOneWidget);
  });

  testWidgets('editing a value marks it Edited', (tester) async {
    await goToReviewStep(tester);

    await enterVisible(tester, 'idNumber', '1234-5678-9012-0000');

    expect(find.text('Edited'), findsOneWidget);
  });

  testWidgets('an emptied Address blocks Continue until filled in', (
    tester,
  ) async {
    await goToReviewStep(tester);
    await enterVisible(tester, 'address', '');

    await tapVisible(tester, find.text('Looks good, continue'));
    expect(find.text('Check your details'), findsOneWidget);
    expect(find.text('This field is required'), findsOneWidget);

    await enterVisible(tester, 'address', '45 Abanao St, Baguio City');
    await tapVisible(tester, find.text('Looks good, continue'));
    expect(find.byKey(const ValueKey('password')), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('an unreadable photo is refused and the buyer stays put', (
    tester,
  ) async {
    scanner.result = const ScannedId(idType: IdType.driversLicense);
    await goToIdStep(tester);
    await pickFromGallery(tester);

    expect(find.text('Upload a valid ID'), findsOneWidget);
    expect(find.text(unreadable), findsOneWidget);
    expect(find.text('Check your details'), findsNothing);
    // No accepted photo yet, so nothing to continue with.
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('a photo of something other than an accepted ID is refused', (
    tester,
  ) async {
    // A name was read, but no accepted ID type was recognized.
    scanner.result = const ScannedId(firstName: 'Juan', lastName: 'Dela Cruz');
    await goToIdStep(tester);
    await pickFromGallery(tester);

    expect(find.text('Upload a valid ID'), findsOneWidget);
    expect(find.text(notAnId), findsOneWidget);
  });

  testWidgets('a failure while reading counts as unreadable', (tester) async {
    scanner.error = Exception('ML Kit failed');
    await goToIdStep(tester);
    await pickFromGallery(tester);

    expect(find.text('Upload a valid ID'), findsOneWidget);
    expect(find.text(unreadable), findsOneWidget);
  });

  testWidgets('a refused retake keeps the earlier photo and edits', (
    tester,
  ) async {
    await goToReviewStep(tester);
    await enterVisible(tester, 'address', '45 Abanao St, Baguio City');
    await tapVisible(tester, find.byKey(const ValueKey('retakeId')));

    scanner.result = ScannedId.nothing;
    await pickFromGallery(tester);
    expect(find.text(notAnId), findsOneWidget);

    // The photo read earlier still stands: carry on to its details.
    await tapVisible(tester, find.text('Next'));
    expect(find.text('Check your details'), findsOneWidget);
    expect(fieldText(tester, 'address'), '45 Abanao St, Baguio City');
  });

  testWidgets('a new pick clears the refusal message', (tester) async {
    scanner.result = ScannedId.nothing;
    await goToIdStep(tester);
    await pickFromGallery(tester);
    expect(find.text(notAnId), findsOneWidget);

    scanner.result = _philsys;
    await pickFromGallery(tester);
    expect(find.text('Check your details'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('retakeId')));
    expect(find.text(notAnId), findsNothing);
  });

  testWidgets('a refused camera permission explains how to fix it', (
    tester,
  ) async {
    picker.error = PlatformException(code: 'camera_access_denied');
    await goToIdStep(tester);

    await tapVisible(tester, find.byKey(const ValueKey('takeIdPhoto')));

    expect(
      find.text('Allow camera access in Settings to take a photo.'),
      findsOneWidget,
    );
    expect(find.text('Upload a valid ID'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('Retake goes back to the photo step', (tester) async {
    await goToReviewStep(tester);

    await tapVisible(tester, find.byKey(const ValueKey('retakeId')));

    expect(find.text('Upload a valid ID'), findsOneWidget);
  });

  testWidgets('blocks submission when Confirm Password does not match', (
    tester,
  ) async {
    stubRegisterSuccess();
    await goToPasswordStep(tester);

    await enterVisible(tester, 'password', 'a-long-passphrase');
    await enterVisible(tester, 'confirmPassword', 'a-different-passphrase');
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('Sign Up'));

    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(registerCall);
  });

  testWidgets('nothing is sent before Sign Up; Sign Up sends the entered '
      'name and phone with the ID details', (tester) async {
    stubRegisterSuccess();
    await goToPasswordStep(tester);
    verifyNever(registerCall);

    expect(find.text('Juan Santos Dela Cruz'), findsOneWidget);
    await enterVisible(tester, 'password', 'a-long-passphrase');
    await enterVisible(tester, 'confirmPassword', 'a-long-passphrase');
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('Sign Up'));

    final captured = verify(
      () => mockRepository.register(
        'buyer@example.com',
        'a-long-passphrase',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        middleName: 'Santos',
        countryCode: any(named: 'countryCode'),
        roleName: 'BUYER',
        profile: captureAny(named: 'profile'),
      ),
    ).captured;
    final profile = captured.single as RegistrationProfile;
    expect(profile.phoneNumber, '+639171234567');
    expect(profile.dateOfBirth, DateTime(1994, 3, 15));
    expect(profile.sex, Sex.male);
    expect(
      profile.address,
      '123 Session Rd, Brgy. Session Road, Baguio City, Benguet',
    );
    expect(profile.idType, IdType.philsys);
    expect(profile.idNumber, '1234-5678-9012-3456');
    expect(profile.idPhotoPath, '/photos/id.jpg');
    expect(find.text('Success'), findsOneWidget);
  });

  testWidgets('the name is never taken from the ID', (tester) async {
    stubRegisterSuccess();
    // Typed in lowercase; the ID prints "Juan" / "Dela Cruz".
    await goToIdStep(tester, first: 'juan', last: 'dela cruz');
    await pickFromGallery(tester);
    await tapVisible(tester, find.text('Looks good, continue'));
    await enterVisible(tester, 'password', 'a-long-passphrase');
    await enterVisible(tester, 'confirmPassword', 'a-long-passphrase');
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('Sign Up'));

    verify(
      () => mockRepository.register(
        any(),
        any(),
        firstName: 'juan',
        lastName: 'dela cruz',
        middleName: any(named: 'middleName'),
        countryCode: any(named: 'countryCode'),
        roleName: any(named: 'roleName'),
        profile: any(named: 'profile'),
      ),
    ).called(1);
  });
}
