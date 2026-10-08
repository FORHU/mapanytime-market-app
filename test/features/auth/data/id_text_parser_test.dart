import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_text_parser.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';

final _today = DateTime(2026, 10, 7);

ScannedId _parse(String text) =>
    IdTextParser.parse(text.trim().split('\n'), today: _today);

void main() {
  test('reads a PhilSys National ID', () {
    final id = _parse('''
REPUBLIKA NG PILIPINAS
Republic of the Philippines
PAMBANSANG PAGKAKAKILANLAN
Philippine Identification Card
1234-5678-9012-3456
Apelyido/Last Name
DELA CRUZ
Mga Pangalan/Given Names
JUAN
Gitnang Apelyido/Middle Name
SANTOS
Petsa ng Kapanganakan/Date of Birth
MARCH 15, 1994
Tirahan/Address
123 SESSION RD, BRGY. SESSION ROAD,
BAGUIO CITY, BENGUET 2600
''');

    expect(id.idType, IdType.philsys);
    expect(id.lastName, 'Dela Cruz');
    expect(id.firstName, 'Juan');
    expect(id.dateOfBirth, DateTime(1994, 3, 15));
    expect(id.idNumber, '1234-5678-9012-3456');
    // Both address lines joined into one; the ZIP code is not kept.
    expect(
      id.address,
      '123 Session Rd, Brgy. Session Road, Baguio City, Benguet',
    );

    // Labeled values are trusted; the missing sex is flagged for review.
    expect(id.unsure, contains(IdField.sex));
    for (final sure in [
      IdField.idType,
      IdField.firstName,
      IdField.lastName,
      IdField.dateOfBirth,
      IdField.idNumber,
      IdField.address,
    ]) {
      expect(id.unsure, isNot(contains(sure)), reason: '$sure');
    }
    expect(id.rejection, isNull);
  });

  test("reads a driver's license and flags what it had to guess", () {
    final id = _parse('''
REPUBLIC OF THE PHILIPPINES
DEPARTMENT OF TRANSPORTATION
LAND TRANSPORTATION OFFICE
DRIVER'S LICENSE
Last Name, First Name, Middle Name
DELA CRUZ, JUAN SANTOS
Nationality Sex Date of Birth Weight (kg) Height(m)
PHL M 1994/03/15 70 1.70
Address
123 SESSION RD, BAGUIO CITY, BENGUET 2600
License No. Expiration Date
A12-34-567890 2030/03/15
''');

    expect(id.idType, IdType.driversLicense);
    expect(id.lastName, 'Dela Cruz');
    expect(id.firstName, 'Juan'); // "Santos" (middle) is not read
    // From the unlabeled value row: the earliest past date, and the lone "M".
    expect(id.dateOfBirth, DateTime(1994, 3, 15));
    expect(id.sex, Sex.male);
    expect(id.idNumber, 'A12-34-567890');
    expect(id.address, '123 Session Rd, Baguio City, Benguet');
    expect(
      id.unsure,
      containsAll({
        IdField.firstName,
        IdField.dateOfBirth,
        IdField.sex,
      }),
    );
    expect(id.unsure, isNot(contains(IdField.idNumber)));
  });

  test('reads a passport, using the machine-readable zone', () {
    final id = _parse('''
REPUBLIKA NG PILIPINAS
PASAPORTE / PASSPORT
Apelyido/Surname
DELA CRUZ
Pangalan/Given names
JUAN
Panggitnang Apelyido/Middle name
SANTOS
Petsa ng kapanganakan/Date of birth
15 MAR 1994
P<PHLDELA<CRUZ<<JUAN<<<<<<<<<<<<<<<<<<<<<<<<
P1234567A2PHL9403156M3001019<<<<<<<<<<<<<<02
''');

    expect(id.idType, IdType.passport);
    expect(id.lastName, 'Dela Cruz');
    expect(id.firstName, 'Juan');
    expect(id.dateOfBirth, DateTime(1994, 3, 15));
    expect(id.sex, Sex.male);
    expect(id.idNumber, 'P1234567A');
    expect(id.unsure, isNot(contains(IdField.sex)));
    // Passports have no address.
    expect(id.address, isEmpty);
    expect(id.unsure, contains(IdField.address));
  });

  test('falls back to the MRZ when the printed names are unreadable', () {
    final id = _parse('''
PASSPORT
P<PHLDELA<CRUZ<<JUAN<<<<<<<<<<<<<<<<<<<<<<<<
P1234567A2PHL9403156M3001019<<<<<<<<<<<<<<02
''');
    expect(id.lastName, 'Dela Cruz');
    expect(id.firstName, 'Juan');
    expect(id.dateOfBirth, DateTime(1994, 3, 15));
  });

  test('a photo that is not an ID is refused as not an ID', () {
    final id = _parse('''
SM SUPERMARKET
TOTAL 1,234.00
THANK YOU
''');
    expect(id.rejection, IdRejection.notAnId);
    expect(id.idType, isNull);
    expect(id.unsure, containsAll({IdField.idType, IdField.firstName}));
  });

  group('dates', () {
    DateTime? dob(String value) => _parse('Date of Birth\n$value').dateOfBirth;

    test('accepts the formats printed on PH IDs', () {
      expect(dob('1994/03/15'), DateTime(1994, 3, 15));
      expect(dob('1994-03-15'), DateTime(1994, 3, 15));
      expect(dob('03/15/1994'), DateTime(1994, 3, 15));
      expect(dob('MAR. 15 1994'), DateTime(1994, 3, 15));
      expect(dob('15 MAR 1994'), DateTime(1994, 3, 15));
    });

    test('rejects impossible and future dates', () {
      expect(dob('02/30/1994'), isNull);
      expect(dob('2030/01/01'), isNull);
    });
  });

  group("driver's license name, as OCR really splits it", () {
    test('a label word split onto its own line is not taken as the name', () {
      // From a real scan: "Name" (the end of the label) came out as its own
      // line and used to become the last name.
      final id = _parse('''
LAND TRANSPORTATION OFFICE
NON-PROFESSIONAL DRIVER'S LICENSE
Last Name, First Name, Middle
Name
DELA CRUZ, JOSIE
Nationality Sex Date of Birth Weight (kg) Height(m)
PHL F YYYY/MM/DD
''');
      expect(id.idType, IdType.driversLicense);
      expect(id.lastName, 'Dela Cruz');
      expect(id.firstName, 'Josie');
      expect(id.unsure, isNot(contains(IdField.lastName)));
      expect(id.sex, Sex.female);
      // The specimen card prints placeholders, not a date.
      expect(id.dateOfBirth, isNull);
    });

    test('finds the name under a label split into three lines', () {
      final id = _parse('''
DRIVER'S LICENSE
Last Name
First Name
Middle Name
DELA CRUZ, JUAN PEDRO GARCIA
''');
      expect(id.lastName, 'Dela Cruz');
      expect(id.firstName, 'Juan Pedro');
      expect(id.unsure, isNot(contains(IdField.lastName)));
      // "Garcia" is taken for the middle name and dropped; "Pedro" might
      // be a middle name too, so the first name is flagged.
      expect(id.unsure, contains(IdField.firstName));
    });

    test('falls back to the comma name line when the label is unreadable', () {
      final id = _parse('''
DRIVER'S LICENSE
L@st Nme, Frst Nme
BAGUIO CITY, BENGUET
DELA CRUZ, JUAN PEDRO GARCIA
''');
      // Skips the address-looking line, and flags the guess.
      expect(id.lastName, 'Dela Cruz');
      expect(id.firstName, 'Juan Pedro');
      expect(
        id.unsure,
        containsAll({IdField.lastName, IdField.firstName}),
      );
    });

    test('leaves the name empty rather than using label leftovers', () {
      final id = _parse('''
DRIVER'S LICENSE
Last Name, First Name, Middle Name
Name
Nationality Sex Date of Birth
PHL M 1990/01/01
''');
      expect(id.lastName, isEmpty);
      expect(id.firstName, isEmpty);
      expect(id.unsure, containsAll({IdField.lastName, IdField.firstName}));
      // A recognized license without a readable name is refused.
      expect(id.rejection, IdRejection.unreadable);
    });

    test('a split PhilSys label still finds the value below', () {
      final id = _parse('''
Philippine Identification Card
Apelyido/Last
Name
DELA CRUZ
''');
      expect(id.lastName, 'Dela Cruz');
    });
  });

  test('an ID with only one of the two names read is unreadable', () {
    // Both names are needed to check them against what the buyer entered.
    const lastOnly = ScannedId(idType: IdType.philsys, lastName: 'Dela Cruz');
    const firstOnly = ScannedId(idType: IdType.philsys, firstName: 'Juan');
    expect(lastOnly.rejection, IdRejection.unreadable);
    expect(firstOnly.rejection, IdRejection.unreadable);
  });

  test('a license "LAST, FIRST, MIDDLE" line keeps only last and first', () {
    final id = _parse('''
DRIVER'S LICENSE
Last Name, First Name, Middle Name
DELA CRUZ, JUAN, SANTOS
''');
    expect(id.lastName, 'Dela Cruz');
    expect(id.firstName, 'Juan');
    expect(id.unsure, isNot(contains(IdField.firstName)));
  });

  test('normalizes a PhilSys number read with spaces', () {
    final id = _parse('Philippine Identification Card\n1234 5678 9012 3456');
    expect(id.idNumber, '1234-5678-9012-3456');
  });
}
