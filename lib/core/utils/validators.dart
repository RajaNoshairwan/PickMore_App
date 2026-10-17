class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    final r = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!r.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  static String? required(String? v, [String label = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone required';
    if (v.trim().length < 8) return 'Invalid phone';
    return null;
  }
}