import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/token_storage.dart';
import '../constants/karnataka_places.dart';
import '../../features/doctor_registration/provider/care_filter_constants.dart';

/// Resolved marketplace location used as default city / nearby sort.
class UserLocationState {
  const UserLocationState({
    this.city,
    this.place,
    this.latitude,
    this.longitude,
    this.isResolving = false,
    this.hasResolved = false,
  });

  final String? city;
  /// Locality / area (e.g. neighbourhood) when reverse-geocoded.
  final String? place;
  final double? latitude;
  final double? longitude;
  final bool isResolving;
  final bool hasResolved;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get displayCity =>
      (city != null && city!.trim().isNotEmpty) ? city!.trim() : 'All cities across India';

  /// "Place, City" for search boxes; falls back to city or place alone.
  String? get displayPlaceCity {
    final c = city?.trim();
    final p = place?.trim();
    final hasCity = c != null && c.isNotEmpty;
    final hasPlace = p != null && p.isNotEmpty;
    if (hasPlace && hasCity) {
      if (p.toLowerCase() == c.toLowerCase()) return c;
      return '$p, $c';
    }
    if (hasCity) return c;
    if (hasPlace) return p;
    return null;
  }

  UserLocationState copyWith({
    String? city,
    String? place,
    double? latitude,
    double? longitude,
    bool? isResolving,
    bool? hasResolved,
    bool clearCity = false,
    bool clearPlace = false,
  }) {
    return UserLocationState(
      city: clearCity ? null : (city ?? this.city),
      place: clearPlace ? null : (place ?? this.place),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isResolving: isResolving ?? this.isResolving,
      hasResolved: hasResolved ?? this.hasResolved,
    );
  }
}

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  UserLocationNotifier() : super(const UserLocationState()) {
    _loadCached();
  }

  final _storage = TokenStorage.instance;
  bool _promptInFlight = false;
  /// True after the first location prompt in this process.
  /// Resume-from-background must not show another system dialog.
  bool _askedThisLaunch = false;

  Future<void> _loadCached() async {
    final city = await _storage.getPreferredCity();
    final place = await _storage.getPreferredPlace();
    final lat = await _storage.getLastLatitude();
    final lng = await _storage.getLastLongitude();
    if (!mounted) return;
    if ((city != null && city.isNotEmpty) ||
        (place != null && place.isNotEmpty) ||
        (lat != null && lng != null)) {
      state = state.copyWith(
        city: city,
        place: place,
        latitude: lat,
        longitude: lng,
        hasResolved: true,
      );
    }
  }

  /// Asks for location on a fresh app process, then resolves city.
  ///
  /// Safe to call from home and other screens: the OS dialog is shown at most
  /// once per launch. Returning from the background does not prompt again.
  Future<void> ensureResolved(
    BuildContext context, {
    bool forcePrompt = false,
  }) async {
    if (_promptInFlight || state.isResolving) return;

    if (_askedThisLaunch && !forcePrompt) {
      if (!_promptInFlight) {
        await _refreshSilently();
      }
      return;
    }

    if (!context.mounted) return;
    _askedThisLaunch = true;
    _promptInFlight = true;
    state = state.copyWith(isResolving: true);
    try {
      final ready = await LocationService.ensureReady(context);
      await _storage.setLocationPrompted(true);
      if (!ready || !context.mounted) {
        state = state.copyWith(isResolving: false, hasResolved: true);
        return;
      }

      final position = await LocationService.getCurrentPosition(
        requestPermissionIfNeeded: false,
      );
      await _applyCoordinates(position.latitude, position.longitude);
    } on LocationFailure {
      state = state.copyWith(isResolving: false, hasResolved: true);
    } catch (_) {
      state = state.copyWith(isResolving: false, hasResolved: true);
    } finally {
      _promptInFlight = false;
    }
  }

  /// Applies a location picked from search, GPS, or a saved address.
  Future<void> applySelected({
    required String addressLine,
    String? city,
    String? label,
    double? latitude,
    double? longitude,
  }) async {
    final resolvedCity = normalizeMarketplaceCity(city) ??
        normalizeMarketplaceCity(addressLine);
    final rawPlace = () {
      final named = (label ?? '').trim();
      if (named.isNotEmpty &&
          named.toLowerCase() != 'current location' &&
          named.toLowerCase() != 'selected location') {
        return named;
      }
      return addressLine.split(',').first.trim();
    }();
    String? place = rawPlace.isEmpty ? null : rawPlace;
    if (resolvedCity != null &&
        place != null &&
        place.toLowerCase() == resolvedCity.toLowerCase()) {
      place = null;
    }

    await _storage.saveLocationPreference(
      city: resolvedCity,
      place: place ?? '',
      latitude: latitude,
      longitude: longitude,
      replaceCoordinates: true,
    );
    if (!mounted) return;
    state = UserLocationState(
      city: resolvedCity,
      place: place,
      latitude: latitude,
      longitude: longitude,
      isResolving: false,
      hasResolved: true,
    );
  }

  Future<void> _refreshSilently() async {
    try {
      if (!await LocationService.isServiceEnabled()) return;
      final perm = await LocationService.checkPermission();
      if (!LocationService.permissionGranted(perm)) return;
      final position = await LocationService.getCurrentPosition(
        requestPermissionIfNeeded: false,
      );
      await _applyCoordinates(position.latitude, position.longitude);
    } catch (_) {}
  }

  Future<void> _applyCoordinates(double latitude, double longitude) async {
    String? city = state.city;
    String? place = state.place;
    try {
      final resolved = await GeocodingService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      city = normalizeMarketplaceCity(resolved.city) ??
          normalizeMarketplaceCity(resolved.address) ??
          city;
      final rawPlace = resolved.place.trim().isNotEmpty
          ? resolved.place.trim()
          : resolved.address.split(',').first.trim();
      if (rawPlace.isNotEmpty &&
          (city == null || rawPlace.toLowerCase() != city.toLowerCase())) {
        place = rawPlace;
      } else {
        place = null;
      }
    } catch (_) {
      // Keep coords even if reverse geocode fails.
    }

    await _storage.saveLocationPreference(
      city: city,
      place: place ?? '',
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    state = UserLocationState(
      city: city,
      place: place,
      latitude: latitude,
      longitude: longitude,
      isResolving: false,
      hasResolved: true,
    );
  }
}

/// Maps reverse-geocoded place names onto marketplace city filter values.
String? normalizeMarketplaceCity(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  const aliases = <String, String>{
    'bengaluru': 'Bengaluru',
    'bangalore': 'Bengaluru',
    'mysuru': 'Mysuru',
    'mysore': 'Mysuru',
    'mangaluru': 'Mangaluru',
    'mangalore': 'Mangaluru',
    'hubballi': 'Hubballi',
    'hubli': 'Hubballi',
    'belagavi': 'Belagavi',
    'belgaum': 'Belagavi',
    'kalaburagi': 'Kalaburagi',
    'gulbarga': 'Kalaburagi',
    'ballari': 'Ballari',
    'bellary': 'Ballari',
    'vijayapura': 'Vijayapura',
    'bijapur': 'Vijayapura',
    'shivamogga': 'Shivamogga',
    'shimoga': 'Shivamogga',
    'tumakuru': 'Tumakuru',
    'tumkur': 'Tumakuru',
    'davanagere': 'Davanagere',
    'davangere': 'Davanagere',
    'hosapete': 'Hosapete',
    'hospet': 'Hosapete',
    'gurugram': 'Gurgaon',
    'gurgaon': 'Gurgaon',
    'bombay': 'Mumbai',
    'mumbai': 'Mumbai',
    'madras': 'Chennai',
    'chennai': 'Chennai',
    'calcutta': 'Kolkata',
    'kolkata': 'Kolkata',
    'new delhi': 'Delhi',
    'delhi': 'Delhi',
    'navi mumbai': 'Mumbai',
    'thiruvananthapuram': 'Thiruvananthapuram',
    'trivandrum': 'Thiruvananthapuram',
  };

  final lower = trimmed.toLowerCase();
  if (aliases.containsKey(lower)) return aliases[lower];

  String? matchToken(String token) {
    final t = token.trim().toLowerCase();
    if (t.isEmpty || t == 'karnataka' || t == 'india') return null;
    if (aliases.containsKey(t)) return aliases[t];
    for (final city in doctorSearchCities) {
      if (city.toLowerCase() == t) return city;
    }
    for (final entry in karnatakaPlaceAliases.entries) {
      for (final alias in entry.value) {
        if (alias.toLowerCase() == t) return entry.key;
      }
    }
    return null;
  }

  // Prefer the most local address token (town) over district/state.
  for (final part in trimmed.split(RegExp(r'[,/|]'))) {
    final matched = matchToken(part);
    if (matched != null) return matched;
  }

  for (final entry in aliases.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }

  String? best;
  var bestLen = 0;
  for (final city in doctorSearchCities) {
    final cityLower = city.toLowerCase();
    if (cityLower.length < 3) continue;
    if (lower.contains(cityLower) && cityLower.length > bestLen) {
      best = city;
      bestLen = cityLower.length;
    }
  }
  if (best != null) return best;

  // Prefer a short place name for API city filters.
  final firstPart = trimmed.split(',').first.trim();
  return firstPart.isEmpty ? trimmed : firstPart;
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  return UserLocationNotifier();
});

/// Helper to append `city` query when navigating from home.
String routeWithPreferredCity(String route, String? city) {
  if (city == null || city.trim().isEmpty) return route;
  final uri = Uri.parse(route);
  final params = Map<String, String>.from(uri.queryParameters);
  params.putIfAbsent('city', () => city.trim());
  return uri.replace(queryParameters: params).toString();
}
