/// Pure form-field validators. Return `null` when valid, else an error string.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
  );

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (v.length > 128) return 'Password must be 128 characters or fewer';
    return null;
  }

  static String? notEmpty(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required';
    return null;
  }

  /// A Philippine mobile number, typed as `9171234567`, `09171234567` or
  /// `+639171234567` (spaces and dashes allowed).
  static String? phMobile(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required';
    if (normalizePhMobile(value) == null) {
      return 'Use a PH mobile number, like 917 123 4567';
    }
    return null;
  }

  /// [value] as E.164 (`+639171234567`), or null if it isn't a PH mobile.
  static String? normalizePhMobile(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    final match = RegExp(r'^(?:\+?63|0)?(9\d{9})$').firstMatch(digits);
    return match == null ? null : '+63${match[1]}';
  }
}
