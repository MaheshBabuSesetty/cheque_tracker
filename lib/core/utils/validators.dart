/// Pure form-field validators shared across features. Returns `null` when
/// valid, or an error string to show under the field.
class Validators {
  const Validators._();

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? notEmpty(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }
}
