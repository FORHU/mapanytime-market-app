import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_name_match.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_text_parser.dart';

bool _matches(
  String first,
  String last, {
  required String idFirst,
  required String idLast,
}) => idNameMatches(
  enteredFirst: first,
  enteredLast: last,
  id: ScannedId(firstName: idFirst, lastName: idLast),
);

void main() {
  test('the same name matches', () {
    expect(
      _matches('Juan', 'Dela Cruz', idFirst: 'Juan', idLast: 'Dela Cruz'),
      isTrue,
    );
  });

  test('ignores case, spacing, punctuation and accents', () {
    expect(
      _matches('juan', 'DELA CRUZ', idFirst: 'Juan', idLast: 'Dela Cruz'),
      isTrue,
    );
    expect(
      _matches('Juan', 'De la Cruz', idFirst: 'Juan', idLast: 'Dela Cruz'),
      isTrue,
    );
    expect(
      _matches('Juan', 'Dela-Cruz', idFirst: 'Juan', idLast: 'Dela Cruz'),
      isTrue,
    );
    expect(_matches('José', 'Peña', idFirst: 'Jose', idLast: 'Pena'), isTrue);
    expect(
      _matches('  Juan ', 'Dela  Cruz', idFirst: 'Juan', idLast: 'Dela Cruz'),
      isTrue,
    );
  });

  test('the first name may be one of the given names on the ID', () {
    expect(
      _matches(
        'Juan',
        'Dela Cruz',
        idFirst: 'Juan Carlos',
        idLast: 'Dela Cruz',
      ),
      isTrue,
    );
    expect(
      _matches(
        'Juan Carlos',
        'Dela Cruz',
        idFirst: 'Juan Carlos',
        idLast: 'Dela Cruz',
      ),
      isTrue,
    );
    // But every typed word has to be on the ID.
    expect(
      _matches(
        'Juan Miguel',
        'Dela Cruz',
        idFirst: 'Juan Carlos',
        idLast: 'Dela Cruz',
      ),
      isFalse,
    );
  });

  test('allows one misread letter per name', () {
    expect(
      _matches('Juan', 'Dela Cruz', idFirst: 'Juan', idLast: 'Dela Crus'),
      isTrue,
    );
    expect(
      _matches('Josie', 'Dela Cruz', idFirst: 'Jos1e', idLast: 'Dela Cruz'),
      isTrue,
    );
    // A dropped letter counts as one too.
    expect(
      _matches('Juan', 'Dela Cruz', idFirst: 'Juan', idLast: 'Dela Cru'),
      isTrue,
    );
  });

  test('two misread letters is a different name', () {
    expect(
      _matches('Juan', 'Dela Cruz', idFirst: 'Juan', idLast: 'Dela Grus'),
      isFalse,
    );
  });

  test('short names must match exactly', () {
    expect(_matches('Ana', 'Go', idFirst: 'Ana', idLast: 'Go'), isTrue);
    expect(_matches('Ana', 'Go', idFirst: 'Ana', idLast: 'Yu'), isFalse);
    expect(_matches('Ana', 'Go', idFirst: 'Ina', idLast: 'Go'), isFalse);
  });

  test('a different surname or first name does not match', () {
    expect(
      _matches('Juan', 'Santos', idFirst: 'Juan', idLast: 'Dela Cruz'),
      isFalse,
    );
    expect(
      _matches('Pedro', 'Dela Cruz', idFirst: 'Juan', idLast: 'Dela Cruz'),
      isFalse,
    );
  });

  test('nothing read never matches', () {
    expect(
      _matches('Juan', 'Dela Cruz', idFirst: '', idLast: 'Dela Cruz'),
      isFalse,
    );
    expect(_matches('Juan', 'Dela Cruz', idFirst: 'Juan', idLast: ''), isFalse);
    expect(_matches('', '', idFirst: '', idLast: ''), isFalse);
  });

  test('only first and last name are compared, never the middle name', () {
    // The ID's first name is "Juan" (its middle name isn't read): a middle
    // name typed into the first-name box is not on the ID.
    expect(
      _matches(
        'Juan Santos',
        'Dela Cruz',
        idFirst: 'Juan',
        idLast: 'Dela Cruz',
      ),
      isFalse,
    );
    // A first name read as two given names still accepts one of them.
    expect(
      _matches('Juan', 'Dela Cruz', idFirst: 'Juan Pedro', idLast: 'Dela Cruz'),
      isTrue,
    );
  });
}
