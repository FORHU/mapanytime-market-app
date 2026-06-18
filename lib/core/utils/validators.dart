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
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
