import 'dart:math';

import 'package:mapanytime_market_app/features/auth/data/id_scan/id_text_parser.dart';

/// Whether the name the buyer typed is the name printed on [id]. Only first
/// and last name are compared; the middle name is not part of the check.
///
/// Deliberately forgiving about how a name is written and read, never about
/// who it is:
/// - case, spaces, punctuation and accents are ignored ("De la Cruz" =
///   "DELA CRUZ", "Peña" = "PENA");
/// - the typed first name may be one of the ID's given names ("Juan" matches
///   "JUAN CARLOS");
/// - one misread letter per name is allowed for names of 4+ letters, since
///   OCR slips ("DELA CRUS").
bool idNameMatches({
  required String enteredFirst,
  required String enteredLast,
  required ScannedId id,
}) {
  return _lastNameMatches(enteredLast, id.lastName) &&
      _firstNameMatches(enteredFirst, id);
}

bool _lastNameMatches(String entered, String onId) {
  final a = _compact(entered);
  final b = _compact(onId);
  return a.isNotEmpty && b.isNotEmpty && _close(a, b);
}

bool _firstNameMatches(String entered, ScannedId id) {
  final typed = _words(entered);
  if (typed.isEmpty || id.firstName.isEmpty) return false;
  if (_close(_compact(entered), _compact(id.firstName))) return true;

  // Only the ID's first name: the middle name is never read or compared.
  final printed = _words(id.firstName);
  return typed.every((word) => printed.any((p) => _close(word, p)));
}

/// Equal, or one edit apart when both are long enough for that to be a
/// misread letter rather than a different name.
bool _close(String a, String b) {
  if (a == b) return true;
  if (min(a.length, b.length) < 4) return false;
  return _withinOneEdit(a, b);
}

String _compact(String name) => _normalize(name).replaceAll(' ', '');

List<String> _words(String name) =>
    _normalize(name).split(' ').where((w) => w.isNotEmpty).toList();

/// Lowercase, accents folded, anything but letters turned into a space.
String _normalize(String name) {
  final folded = name.toLowerCase().split('').map((c) => _fold[c] ?? c).join();
  return folded
      .replaceAll(RegExp('[^a-z]+'), ' ')
      .trim()
      .replaceAll(RegExp(' +'), ' ');
}

const _fold = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ñ': 'n', 'ç': 'c',
};

/// Levenshtein distance ≤ 1: one substitution, insertion or deletion.
bool _withinOneEdit(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  var i = 0;
  var j = 0;
  var edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (b.length > a.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}
