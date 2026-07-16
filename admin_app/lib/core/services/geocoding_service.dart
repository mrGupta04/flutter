import 'package:dio/dio.dart';

/// Parsed postal address from coordinates.
class ResolvedAddress {
  const ResolvedAddress({
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
  });

  final String address;
  final String city;
  final String state;
  final String pincode;
}

/// Reverse geocoding (coordinates → address). Uses OpenStreetMap Nominatim (works on web).
class GeocodingService {
  GeocodingService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'HealthcareProDoctorRegistration/1.0 (contact: admin@1mgdoctors.com)',
        'Accept': 'application/json',
      },
    ),
  );

  /// Address text → coordinates (for manual address entry).
  static Future<GeocodedPlace> forwardGeocode({
    required String address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    final queryParts = [
      address.trim(),
      if (city != null && city.trim().isNotEmpty) city.trim(),
      if (state != null && state.trim().isNotEmpty) state.trim(),
      if (pincode != null && pincode.trim().isNotEmpty) pincode.trim(),
      'India',
    ];
    final query = queryParts.join(', ');
    if (address.trim().isEmpty) {
      throw GeocodingFailure('Enter an address first.');
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 1,
          'countrycodes': 'in',
        },
      );

      final list = response.data;
      if (list == null || list.isEmpty) {
        throw GeocodingFailure(
          'Could not find that address on the map. Check spelling or try map pin.',
        );
      }

      final first = list.first;
      if (first is! Map<String, dynamic>) {
        throw GeocodingFailure('Could not find that address on the map.');
      }

      final lat = double.tryParse('${first['lat']}');
      final lon = double.tryParse('${first['lon']}');
      if (lat == null || lon == null) {
        throw GeocodingFailure('Could not find that address on the map.');
      }

      final addr = first['address'];
      final resolved = addr is Map<String, dynamic>
          ? _fromNominatimAddress(addr, first['display_name'] as String?)
          : ResolvedAddress(
              address: address.trim(),
              city: city?.trim() ?? '',
              state: state?.trim() ?? '',
              pincode: pincode?.trim() ?? '',
            );

      return GeocodedPlace(
        latitude: lat,
        longitude: lon,
        address: resolved,
      );
    } on DioException catch (e) {
      throw GeocodingFailure(
        e.response?.statusCode == 429
            ? 'Too many address lookups. Wait a moment and try again.'
            : 'Could not look up address. Check your internet connection.',
      );
    } on GeocodingFailure {
      rethrow;
    } catch (_) {
      throw GeocodingFailure('Could not look up that address.');
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
    final city = _firstNonEmpty(addr, [
      'city',
      'town',
      'village',
      'municipality',
      'county',
      'state_district',
      'suburb',
    ]);

    final state = _firstNonEmpty(addr, ['state', 'region']) ?? '';

    final pincode = _firstNonEmpty(addr, ['postcode']) ?? '';

    final streetParts = <String>[
      if (addr['house_number'] != null) '${addr['house_number']}',
      if (addr['road'] != null) '${addr['road']}',
      if (addr['neighbourhood'] != null) '${addr['neighbourhood']}',
      if (addr['suburb'] != null && addr['suburb'] != city) '${addr['suburb']}',
      if (addr['quarter'] != null) '${addr['quarter']}',
    ].where((s) => s.trim().isNotEmpty).toList();

    var line = streetParts.join(', ');
    if (line.isEmpty && displayName != null) {
      final parts = displayName.split(',');
      if (parts.length > 2) {
        line = parts.take(3).join(', ').trim();
      } else {
        line = displayName;
      }
    }

    if (line.isEmpty) {
      throw GeocodingFailure('Address not found for this location.');
    }

    return ResolvedAddress(
      address: line,
      city: city ?? '',
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

/// Coordinates plus resolved address from a forward geocode search.
class GeocodedPlace {
  const GeocodedPlace({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

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
