import '../config/api_config.dart';

/// Resolves relative upload paths to absolute URLs for network loading.
class MediaUrlUtils {
  MediaUrlUtils._();

  static String get _serverOrigin {
    final base = ApiConfig.baseUrl.trim();
    if (base.endsWith('/api/v1/')) {
      return base.substring(0, base.length - '/api/v1/'.length);
    }
    if (base.endsWith('/api/v1')) {
      return base.substring(0, base.length - '/api/v1'.length);
    }
    return base.replaceAll(RegExp(r'/api/v1/?$'), '');
  }

  static String resolve(String? url) {
    if (url == null || url.isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/uploads/')) {
      return '$_serverOrigin$trimmed';
    }
    if (trimmed.startsWith('uploads/')) {
      return '$_serverOrigin/$trimmed';
    }
    if (trimmed.startsWith('/')) {
      return '$_serverOrigin$trimmed';
    }
    return '$_serverOrigin/uploads/$trimmed';
  }

  static bool isPdfUrl(String? url, {String? mimeType}) {
    if (mimeType != null && mimeType.toLowerCase().contains('pdf')) {
      return true;
    }
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf') || lower.contains('.pdf?');
  }

  static bool isImageUrl(String? url, {String? mimeType}) {
    if (mimeType != null) {
      final m = mimeType.toLowerCase();
      if (m.startsWith('image/')) return true;
      if (m.contains('pdf')) return false;
    }
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.contains('.png?') ||
        lower.contains('.jpg?') ||
        lower.contains('.jpeg?');
  }
}
