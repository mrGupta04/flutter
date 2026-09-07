String friendlyErrorMessage(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  final lower = raw.toLowerCase();
  if (lower.contains('is not defined') ||
      lower.contains('referenceerror') ||
      lower.contains('syntaxerror') ||
      lower.contains('typeerror')) {
    return 'Something went wrong. Please try again.';
  }
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network') ||
      lower.contains('timed out') ||
      lower.contains('timeout') ||
      lower.contains('connection')) {
    return 'Check your internet connection and try again.';
  }
  if (lower.contains('401') ||
      lower.contains('unauthorized') ||
      lower.contains('please sign in')) {
    return 'Please sign in to continue.';
  }
  if (raw.contains('DioException') ||
      raw.contains('{') ||
      raw.length > 160) {
    return 'Something went wrong. Please try again.';
  }
  return raw;
}
