import 'package:dio/dio.dart';

/// Parsed postal address from coordinates.
class ResolvedAddress {
  const ResolvedAddress({
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.place = '',
  });

  final String address;
  final String city;
  /// Locality / area (neighbourhood, suburb) when available.
  final String place;
  final String state;
  final String pincode;
}

/// Reverse geocoding (coordinates → address). Uses OpenStreetMap Nominatim.
class GeocodingService {
  GeocodingService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': '1mgCarePatientApp/1.0 (contact: support@1mgdoctors.com)',
        'Accept': 'application/json',
        'Accept-Language': 'en',
      },
    ),
  );

  static Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    int limit = 6,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$trimmed, India',
          'format': 'json',
          'addressdetails': 1,
          'limit': limit.clamp(1, 8),
          'countrycodes': 'in',
          'accept-language': 'en',
        },
      );
      final list = response.data;
      if (list == null || list.isEmpty) return const [];
      final results = <PlaceSuggestion>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        if (lat == null || lon == null) continue;
        final addr = item['address'];
        final display = (item['display_name'] as String?)?.trim() ?? '';
        final resolved = addr is Map<String, dynamic>
            ? _fromNominatimAddress(addr, display)
            : _fromDisplayName(display.isEmpty ? trimmed : display);
        results.add(
          PlaceSuggestion(
            displayName: display.isEmpty ? resolved.address : display,
            latitude: lat,
            longitude: lon,
            address: resolved,
          ),
        );
      }
      return results;
    } on DioException catch (e) {
      throw GeocodingFailure(
        e.response?.statusCode == 429
            ? 'Too many address lookups. Wait a moment and try again.'
            : 'Could not search locations. Check your internet connection.',
      );
    } on GeocodingFailure {
      rethrow;
    } catch (_) {
      throw GeocodingFailure('Could not search locations.');
    }
  }

  static Future<ResolvedAddress> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'addressdetails': 1,
          'accept-language': 'en',
        },
      );

      final data = response.data;
      if (data == null) {
        throw GeocodingFailure('No address data returned.');
      }

      final addr = data['address'];
      if (addr is! Map<String, dynamic>) {
        final display = data['display_name'] as String?;
        if (display != null && display.isNotEmpty) {
          return _fromDisplayName(display);
        }
        throw GeocodingFailure('Could not parse address for this location.');
      }

      return _fromNominatimAddress(addr, data['display_name'] as String?);
    } on DioException catch (e) {
      throw GeocodingFailure(
        e.response?.statusCode == 429
            ? 'Too many address lookups. Wait a moment and try again.'
            : 'Could not look up address. Check your internet connection.',
      );
    } on GeocodingFailure {
      rethrow;
    } catch (_) {
      throw GeocodingFailure('Could not look up address for this location.');
    }
  }

  static ResolvedAddress _fromNominatimAddress(
    Map<String, dynamic> addr,
    String? displayName,
  ) {
    final place = _firstNonEmpty(addr, [
      'neighbourhood',
      'suburb',
      'quarter',
      'city_district',
      'residential',
      'hamlet',
    ]);

    final city = _firstNonEmpty(addr, [
      'city',
      'town',
      'village',
      'municipality',
      'county',
      'state_district',
    ]);

    final state = _firstNonEmpty(addr, ['state', 'region']) ?? '';
    final pincode = _firstNonEmpty(addr, ['postcode']) ?? '';

    final streetParts = <String>[
      if (addr['house_number'] != null) '${addr['house_number']}',
      if (addr['road'] != null) '${addr['road']}',
      if (place != null) place,
    ].where((s) => s.trim().isNotEmpty).toList();

    var line = streetParts.join(', ');
    final display = (displayName ?? '').trim();
    if (display.isNotEmpty) {
      line = display;
    } else if (line.isEmpty) {
      throw GeocodingFailure('Address not found for this location.');
    }

    return ResolvedAddress(
      address: line,
      place: place ?? '',
      city: city ?? place ?? '',
      state: state,
      pincode: pincode.replaceAll(RegExp(r'\s'), ''),
    );
  }

  static ResolvedAddress _fromDisplayName(String displayName) {
    final parts = displayName.split(',').map((p) => p.trim()).toList();
    if (parts.isEmpty) {
      throw GeocodingFailure('Address not found for this location.');
    }
    return ResolvedAddress(
      address: parts.first,
      place: parts.length > 3 ? parts[parts.length - 4] : parts.first,
      city: parts.length > 2 ? parts[parts.length - 3] : '',
      state: parts.length > 1 ? parts[parts.length - 2] : '',
      pincode: '',
    );
  }

  static String? _firstNonEmpty(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final String displayName;
  final double latitude;
  final double longitude;
  final ResolvedAddress address;
}

class GeocodingFailure implements Exception {
  GeocodingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
