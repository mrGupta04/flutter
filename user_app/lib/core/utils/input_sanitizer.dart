/// Input sanitization utilities
class InputSanitizer {
  InputSanitizer._();

  static String sanitizeText(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String sanitizeEmail(String? value) {
    return sanitizeText(value).toLowerCase();
  }

  static String sanitizePhone(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\D'), '').trim();
  }

  static String sanitizeMultiline(String? value) {
    if (value == null) return '';
    return value
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static int? sanitizeInt(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  static double? sanitizeDouble(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(RegExp(r'[^0-9\.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
