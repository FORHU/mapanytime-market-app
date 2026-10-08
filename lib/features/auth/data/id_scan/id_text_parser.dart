import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';

/// A field on the "Check your details" step that can be read from an ID.
enum IdField {
  firstName,
  lastName,
  dateOfBirth,
  sex,
  address,
  idType,
  idNumber,
}

/// What could be read from a photo of a Philippine government ID.
///
/// Empty strings / nulls are fields that weren't found. [unsure] holds the
/// fields the buyer should double-check: missing ones, and ones inferred from
/// position rather than read next to their printed label.
class ScannedId {
  const ScannedId({
    this.idType,
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.sex,
    this.address = '',
    this.idNumber = '',
    this.unsure = const {},
  });

  /// Nothing read — every field is left for the buyer to fill in.
  static const nothing = ScannedId(unsure: {...IdField.values});

  final IdType? idType;

  /// Given name(s) only — the middle name is not read.
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final Sex? sex;

  /// One line, e.g. "123 Session Rd, Brgy. Session Road, Baguio City,
  /// Benguet" — no ZIP code.
  final String address;
  final String idNumber;
  final Set<IdField> unsure;

  /// Why this photo can't be used, or null when it can: it must be one of the
  /// accepted IDs, and the holder's first and last name must have been read
  /// (both are needed to check them against the name the buyer entered).
  IdRejection? get rejection {
    if (idType == null) return IdRejection.notAnId;
    if (firstName.isEmpty || lastName.isEmpty) return IdRejection.unreadable;
    return null;
  }
}

/// Why an ID photo was refused.
enum IdRejection {
  /// None of the accepted IDs was recognized — another card, or not an ID.
  notAnId,

  /// An accepted ID, but too blurry, cropped or glare-covered to read.
  unreadable,

  /// Readable, but the name on it isn't the name the buyer entered. Set by
  /// the sign-up page (see `idNameMatches`), never by the parser.
  nameMismatch,
}

/// Turns the text lines OCR found on an ID photo into a [ScannedId].
///
/// Heuristic by nature: card layouts vary and OCR misreads characters, which
/// is why every value lands in an editable field the buyer reviews.
abstract final class IdTextParser {
  static ScannedId parse(List<String> rawLines, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final lines = [
      for (final l in rawLines) l.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ]..removeWhere((l) => l.isEmpty);
    final upper = [for (final l in lines) l.toUpperCase()];
    final all = upper.join('\n');
    final unsure = <IdField>{};

    final mrz = _Mrz.tryParse(upper, now);
    final idType = _detectType(all) ?? (mrz != null ? IdType.passport : null);
    if (idType == null) unsure.add(IdField.idType);

    final labeled = _labeledValues(upper);

    // --- Names ---
    // Only first and last name are read; the middle name is never scanned
    // (its label is still recognized, so its line isn't taken for another).
    var lastName = labeled[_Label.last] ?? '';
    var firstName = labeled[_Label.given] ?? '';
    final combined = labeled[_Label.combinedName];
    if (combined != null && lastName.isEmpty) {
      // Driver's license: "DELA CRUZ, JUAN SANTOS" under one label.
      final split = _splitCombinedName(combined);
      (lastName, firstName) = (split.last, split.first);
      if (split.ambiguous) unsure.add(IdField.firstName);
    }
    if (mrz != null) {
      if (lastName.isEmpty) lastName = mrz.surname;
      if (firstName.isEmpty) firstName = mrz.givenNames;
    }
    if (lastName.isEmpty &&
        firstName.isEmpty &&
        (idType == null || idType == IdType.driversLicense)) {
      // The label was unreadable: a "LAST, FIRST MIDDLE" line anywhere on a
      // license is almost certainly the name, but it's a guess.
      final line = upper.firstWhere(_isUnlabeledNameLine, orElse: () => '');
      if (line.isNotEmpty) {
        final split = _splitCombinedName(line);
        (lastName, firstName) = (split.last, split.first);
        unsure.addAll({IdField.firstName, IdField.lastName});
      }
    }
    for (final (field, value) in [
      (IdField.firstName, firstName),
      (IdField.lastName, lastName),
    ]) {
      if (!_looksLikeName(value)) unsure.add(field);
    }

    // --- Date of birth ---
    var dateOfBirth = _firstDate(labeled[_Label.dob] ?? '', now) ?? mrz?.dob;
    if (dateOfBirth == null) {
      // Unlabeled: the earliest date on the card is the birth date (issue and
      // expiry dates come later).
      final dates = _allDates(all, now)..sort();
      dateOfBirth = dates.isEmpty ? null : dates.first;
      unsure.add(IdField.dateOfBirth);
    }

    // --- Sex ---
    var sex = _parseSex(labeled[_Label.sex]) ?? mrz?.sex;
    if (sex == null) {
      sex = _standaloneSex(upper);
      unsure.add(IdField.sex);
    }

    // --- Address ---
    final address = _cleanAddress(labeled[_Label.address] ?? '');
    if (address.isEmpty) unsure.add(IdField.address);

    // --- ID number ---
    var idNumber = mrz?.number ?? '';
    if (idNumber.isEmpty) {
      final found = _findIdNumber(all, idType, labeled[_Label.idNumber]);
      idNumber = found.$1;
      if (!found.$2) unsure.add(IdField.idNumber);
    }

    return ScannedId(
      idType: idType,
      firstName: _titleCase(firstName),
      lastName: _titleCase(lastName),
      dateOfBirth: dateOfBirth,
      sex: sex,
      address: _titleCase(address),
      idNumber: idNumber,
      unsure: unsure,
    );
  }

  // ---------------------------------------------------------------------------
  // ID type

  static const _typeKeywords = <IdType, List<String>>{
    IdType.philsys: [
      'PHILIPPINE IDENTIFICATION',
      'PAMBANSANG PAGKAKAKILANLAN',
      'PHILSYS',
    ],
    IdType.driversLicense: [
      "DRIVER'S LICENSE",
      'DRIVERS LICENSE',
      'DRIVER LICENSE',
      'LAND TRANSPORTATION OFFICE',
    ],
    IdType.umid: ['UNIFIED MULTI-PURPOSE', 'UNIFIED MULTI PURPOSE', 'UMID'],
    IdType.postalId: ['POSTAL IDENTITY CARD', 'PHLPOST', 'PHILPOST'],
    IdType.prcId: ['PROFESSIONAL REGULATION COMMISSION'],
    IdType.passport: ['PASSPORT', 'PASAPORTE'],
  };

  static IdType? _detectType(String allUpper) {
    for (final entry in _typeKeywords.entries) {
      if (entry.value.any(allUpper.contains)) return entry.key;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Labeled fields

  /// Printed labels, English and Filipino. Order matters: "GITNANG APELYIDO"
  /// (middle name) must be checked before "APELYIDO" (last name).
  static const _labels = <_Label, List<String>>{
    _Label.middle: [
      'PANGGITNANG APELYIDO',
      'GITNANG APELYIDO',
      'MIDDLE NAME',
    ],
    _Label.last: ['LAST NAME', 'APELYIDO', 'SURNAME'],
    _Label.given: [
      'GIVEN NAMES',
      'GIVEN NAME',
      'MGA PANGALAN',
      'FIRST NAME',
      'PANGALAN',
    ],
    _Label.dob: [
      'PETSA NG KAPANGANAKAN',
      'DATE OF BIRTH',
      'BIRTH DATE',
      'BIRTHDATE',
    ],
    _Label.sex: ['KASARIAN', 'SEX'],
    _Label.address: ['ADDRESS', 'TIRAHAN'],
    _Label.idNumber: [
      'REGISTRATION NO',
      'REG. NO',
      'LICENSE NO',
      'PRN',
      'CRN',
      'PCN',
    ],
  };

  /// Labels found on [line], in the order of [_labels].
  static List<_Label> _labelsOn(String line) {
    final found = <_Label>[];
    var rest = line;
    for (final entry in _labels.entries) {
      final hit = entry.value.where(
        (w) => RegExp('\\b${RegExp.escape(w)}\\b').hasMatch(rest),
      );
      if (hit.isNotEmpty) {
        found.add(entry.key);
        for (final w in hit) {
          rest = rest.replaceAll(w, ' ');
        }
      }
    }
    return found;
  }

  /// Strips every label word and separator from [line], leaving the value
  /// printed on the same line (if any).
  static String _stripLabels(String line) {
    var rest = line;
    for (final words in _labels.values) {
      for (final w in words) {
        rest = rest.replaceAll(RegExp('\\b${RegExp.escape(w)}\\b'), ' ');
      }
    }
    return rest
        .replaceAll(RegExp(r'^[\s/:|.,\-]+|[\s/:|]+$'), '')
        .replaceAll(RegExp(r'\s*/\s*'), ' ')
        .trim();
  }

  static Map<_Label, String> _labeledValues(List<String> upper) {
    final values = <_Label, String>{};
    for (var i = 0; i < upper.length; i++) {
      final line = upper[i];

      // Driver's license prints "Last Name, First Name, Middle Name" as one
      // label over one value line. OCR may split that label ("..., Middle" /
      // "Name"), so only its start is required.
      if (line.contains('LAST NAME') && line.contains('FIRST')) {
        final next = _valueLineAfter(upper, i, _isCombinedName);
        if (next != null) values[_Label.combinedName] ??= next;
        continue;
      }

      final labels = _labelsOn(line);
      // A row of several labels ("Sex Date of Birth Weight") has its values
      // in a row below that can't be paired reliably; the fallbacks cover it.
      if (labels.length != 1) continue;
      final label = labels.single;
      if (values.containsKey(label)) continue;

      var sameLine = _stripLabels(line);
      // "Apelyido/Last" + "Name": the leftover is label, not value.
      if (_isLabelFragment(sameLine)) sameLine = '';
      if (label == _Label.address) {
        final parts = [
          if (sameLine.isNotEmpty) sameLine,
          for (var j = i + 1; j < upper.length && j <= i + 3; j++)
            if (_isAddressContinuation(upper[j])) upper[j] else null,
        ];
        // Stop at the first line that isn't part of the address.
        final end = parts.indexOf(null);
        final kept = (end == -1 ? parts : parts.sublist(0, end))
            .whereType<String>();
        if (kept.isNotEmpty) values[label] = kept.join(', ');
        continue;
      }

      final isName = _nameLabels.contains(label);
      final value = sameLine.isNotEmpty
          ? sameLine
          : _valueLineAfter(
              upper,
              i,
              isName
                  ? (v) => _isCombinedName(v) || _isNameValue(v)
                  : (_) => true,
            );
      if (value == null || value.isEmpty) continue;
      if (isName && _isCombinedName(value)) {
        // A license label split into "Last Name" / "First Name" / "Middle
        // Name" lines: the comma value below belongs to all three.
        values[_Label.combinedName] ??= value;
      } else if (!isName || _isNameValue(value)) {
        values[label] = value;
      }
    }
    return values;
  }

  static const Set<_Label> _nameLabels = {
    _Label.last,
    _Label.given,
    _Label.middle,
  };

  /// The first of the next few lines after label line [i] that passes
  /// [accept]. Leftover label words ("NAME") are skipped; another field's
  /// label ends the search.
  static String? _valueLineAfter(
    List<String> upper,
    int i,
    bool Function(String) accept,
  ) {
    for (var j = i + 1; j < upper.length && j <= i + 3; j++) {
      final line = upper[j];
      if (_isLabelFragment(line)) continue;
      if (_labelsOn(line).isNotEmpty) return null;
      if (accept(line)) return line;
    }
    return null;
  }

  /// Words that only ever appear in name labels, in English and Filipino.
  static const _nameLabelWords = {
    'LAST', 'FIRST', 'MIDDLE', 'GIVEN', 'NAME', 'NAMES', 'SURNAME', //
    'APELYIDO', 'MGA', 'PANGALAN', 'GITNANG', 'PANGGITNANG',
  };

  /// True when every word of [line] is a name-label word: a piece of a label
  /// that OCR split off ("NAME", "NAME, MIDDLE NAME"), never a value.
  static bool _isLabelFragment(String line) {
    final words = line
        .toUpperCase()
        .split(RegExp('[^A-ZÑ]+'))
        .where((w) => w.isNotEmpty);
    return words.isNotEmpty && words.every(_nameLabelWords.contains);
  }

  static bool _isNameValue(String v) =>
      _looksLikeName(v) && !_isLabelFragment(v);

  /// "DELA CRUZ, JUAN PEDRO GARCIA": the license's single name line.
  static final _combinedNameShape = RegExp(
    r"^[A-ZÑ .'\-]+,\s*[A-ZÑ .'\-]+(,\s*[A-ZÑ .'\-]+)*,?$",
  );

  static bool _isCombinedName(String v) =>
      _combinedNameShape.hasMatch(v) && !_isLabelFragment(v);

  /// Words that mark a comma-separated line as an address, not a name.
  static final _addressWords = RegExp(
    r'\b(CITY|BRGY|BGY|BARANGAY|ROAD|RD|STREET|ST|AVE|AVENUE|PROVINCE|'
    r'PHILIPPINES|PILIPINAS|REPUBLIC|REPUBLIKA|MUNICIPALITY)\b',
  );

  static bool _isUnlabeledNameLine(String line) =>
      _isCombinedName(line) &&
      _labelsOn(line).isEmpty &&
      !_addressWords.hasMatch(line);

  /// Last and first name from "LAST, FIRST MIDDLE" or "LAST, FIRST, MIDDLE";
  /// the middle name is dropped. `ambiguous` when the given part has several
  /// words, so the one taken for the middle name may be a second first name.
  static ({String last, String first, bool ambiguous}) _splitCombinedName(
    String value,
  ) {
    final parts = value
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      return (last: parts[0], first: parts[1], ambiguous: false);
    }
    if (parts.length == 2) {
      final words = parts[1].split(' ');
      if (words.length >= 2) {
        return (
          last: parts[0],
          first: words.sublist(0, words.length - 1).join(' '),
          ambiguous: true,
        );
      }
      return (last: parts[0], first: parts[1], ambiguous: false);
    }
    return (last: '', first: '', ambiguous: false);
  }

  static bool _isAddressContinuation(String line) =>
      _labelsOn(line).isEmpty &&
      _allDates(line, DateTime.now()).isEmpty &&
      !RegExp(r'\d{4}-\d{4}-\d{4}').hasMatch(line);

  static bool _looksLikeName(String value) =>
      value.isNotEmpty && RegExp(r"^[A-ZÑ .'\-]+$").hasMatch(value);

  // ---------------------------------------------------------------------------
  // Dates

  static const _months = {
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6, //
    'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
  };

  static final _datePatterns = <(RegExp, DateTime? Function(Match))>[
    // 1994/03/15, 1994-03-15
    (
      RegExp(r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b'),
      (m) => _date(m[1]!, m[2]!, m[3]!),
    ),
    // 03/15/1994 — month first, the Philippine convention.
    (
      RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b'),
      (m) => _date(m[3]!, m[1]!, m[2]!),
    ),
    // MARCH 15, 1994 / MAR. 15 1994
    (
      RegExp(r'\b([A-Z]{3,9})\.? (\d{1,2}),? (\d{4})\b'),
      (m) => _monthDate(m[3]!, m[1]!, m[2]!),
    ),
    // 15 MAR 1994 (passport)
    (
      RegExp(r'\b(\d{1,2}) ([A-Z]{3,9})\.? (\d{4})\b'),
      (m) => _monthDate(m[3]!, m[2]!, m[1]!),
    ),
  ];

  static DateTime? _date(String y, String m, String d) {
    final year = int.parse(y);
    final month = int.parse(m);
    final day = int.parse(d);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    // Reject overflow like Feb 30 rolling into March.
    return date.month == month ? date : null;
  }

  static DateTime? _monthDate(String y, String monthName, String d) {
    final month = _months[monthName.substring(0, 3)];
    if (month == null) return null;
    return _date(y, '$month', d);
  }

  static List<DateTime> _allDates(String text, DateTime now) {
    final upperText = text.toUpperCase();
    return [
      for (final (re, build) in _datePatterns)
        for (final m in re.allMatches(upperText))
          if (build(m) case final d? when d.year >= 1900 && !d.isAfter(now)) d,
    ];
  }

  static DateTime? _firstDate(String text, DateTime now) {
    final dates = _allDates(text, now);
    return dates.isEmpty ? null : dates.first;
  }

  // ---------------------------------------------------------------------------
  // Sex

  static Sex? _parseSex(String? value) {
    if (value == null || value.isEmpty) return null;
    final word = value.split(RegExp(r'[\s/]')).first;
    return switch (word) {
      'M' || 'MALE' || 'LALAKI' => Sex.male,
      'F' || 'FEMALE' || 'BABAE' => Sex.female,
      _ => null,
    };
  }

  /// A lone "M"/"F" token, e.g. in the driver's license value row
  /// "PHL M 1994/03/15 70 1.70".
  static Sex? _standaloneSex(List<String> upper) {
    for (final line in upper) {
      for (final token in line.split(' ')) {
        if (token == 'M' || token == 'MALE') return Sex.male;
        if (token == 'F' || token == 'FEMALE') return Sex.female;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Address

  /// The address as one line: labeled lines joined, "Philippines" and a
  /// trailing ZIP code dropped (ZIP isn't collected).
  static String _cleanAddress(String raw) {
    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p.toUpperCase() != 'PHILIPPINES')
        .toList();
    if (parts.isNotEmpty) {
      final last = parts.removeLast().replaceFirst(RegExp(r'\s*\b\d{4}$'), '');
      if (last.isNotEmpty) parts.add(last);
    }
    return parts.join(', ');
  }

  // ---------------------------------------------------------------------------
  // ID number

  static final _idPatterns = <IdType, RegExp>{
    IdType.philsys: RegExp(r'\b\d{4}[- ]\d{4}[- ]\d{4}[- ]\d{4}\b'),
    IdType.driversLicense: RegExp(r'\b[A-Z]\d{2}-\d{2}-\d{6}\b'),
    IdType.umid: RegExp(r'\b\d{4}-\d{7}-\d\b'),
    IdType.passport: RegExp(r'\b[A-Z]{1,2}\d{6,7}[A-Z]?\b'),
    IdType.postalId: RegExp(r'\b\d{12}\b'),
    IdType.prcId: RegExp(r'\b\d{7}\b'),
  };

  /// Formats with a check pattern specific enough to trust when matched.
  static const Set<IdType> _distinctive = {
    IdType.philsys,
    IdType.driversLicense,
    IdType.umid,
    IdType.passport,
  };

  /// The ID number and whether it can be trusted.
  static (String, bool) _findIdNumber(
    String allUpper,
    IdType? type,
    String? labeledValue,
  ) {
    String normalize(String v) =>
        type == IdType.philsys ? v.replaceAll(' ', '-') : v;

    if (type != null) {
      final m = _idPatterns[type]!.firstMatch(allUpper);
      if (m != null) return (normalize(m[0]!), _distinctive.contains(type));
    }
    if (labeledValue != null && labeledValue.isNotEmpty) {
      return (labeledValue.split(' ').first, false);
    }
    // Unknown type: try the distinctive formats.
    for (final t in _distinctive) {
      final m = _idPatterns[t]!.firstMatch(allUpper);
      if (m != null) return (m[0]!, false);
    }
    return ('', false);
  }

  // ---------------------------------------------------------------------------

  /// "DELA CRUZ" → "Dela Cruz". Tokens with digits ("2600", "123-B") keep
  /// their case.
  static String _titleCase(String value) => value
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map(
        (w) => RegExp(r'\d').hasMatch(w)
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}

enum _Label { last, given, middle, combinedName, dob, sex, address, idNumber }

/// The two-line machine-readable zone on a passport's data page.
class _Mrz {
  const _Mrz({
    required this.surname,
    required this.givenNames,
    required this.number,
    this.dob,
    this.sex,
  });

  final String surname;
  final String givenNames;
  final String number;
  final DateTime? dob;
  final Sex? sex;

  static _Mrz? tryParse(List<String> upper, DateTime now) {
    for (var i = 0; i + 1 < upper.length; i++) {
      final l1 = upper[i].replaceAll(' ', '');
      final l2 = upper[i + 1].replaceAll(' ', '');
      if (!l1.startsWith('P<') || l1.length < 30 || l2.length < 28) continue;

      final names = l1.substring(5).split('<<');
      String clean(String s) => s.replaceAll('<', ' ').trim();

      final yy = int.tryParse(l2.substring(13, 15));
      final mm = l2.substring(15, 17);
      final dd = l2.substring(17, 19);
      DateTime? dob;
      if (yy != null) {
        // YY → the latest century that isn't in the future.
        final century = 2000 + yy > now.year ? 1900 : 2000;
        dob = IdTextParser._date('${century + yy}', mm, dd);
      }

      return _Mrz(
        surname: clean(names.first),
        givenNames: names.length > 1 ? clean(names[1]) : '',
        number: l2.substring(0, 9).replaceAll('<', ''),
        dob: dob,
        sex: switch (l2[20]) {
          'M' => Sex.male,
          'F' => Sex.female,
          _ => null,
        },
      );
    }
    return null;
  }
}
