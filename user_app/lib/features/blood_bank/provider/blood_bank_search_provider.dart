import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/repositories/blood_bank_repository.dart';

final bloodBankRepositoryProvider = Provider((ref) => BloodBankRepository());

enum BloodBankCareFilter {
  all('All'),
  available24x7('24×7'),
  emergencySupply('Emergency'),
  homeDelivery('Home delivery'),
  openNow('Open now'),
  hasDiscount('Discount');

  const BloodBankCareFilter(this.label);
  final String label;
}

class BloodBankSearchParams {
  const BloodBankSearchParams({
    this.query,
    this.city,
    this.pincode,
    this.area,
    this.bloodGroup,
    this.componentType,
    this.careFilter = BloodBankCareFilter.all,
    this.latitude,
    this.longitude,
    this.maxDistanceKm,
    this.maxPrice,
    this.minRating,
  });

  final String? query;
  final String? city;
  final String? pincode;
  final String? area;
  final String? bloodGroup;
  final String? componentType;
  final BloodBankCareFilter careFilter;
  final double? latitude;
  final double? longitude;
  final double? maxDistanceKm;
  final double? maxPrice;
  final double? minRating;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodBankSearchParams &&
        other.query == query &&
        other.city == city &&
        other.pincode == pincode &&
        other.area == area &&
        other.bloodGroup == bloodGroup &&
        other.componentType == componentType &&
        other.careFilter == careFilter &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.maxDistanceKm == maxDistanceKm &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating;
  }

  @override
  int get hashCode => Object.hash(
        query,
        city,
        pincode,
        area,
        bloodGroup,
        componentType,
        careFilter,
        latitude,
        longitude,
        maxDistanceKm,
        maxPrice,
        minRating,
      );
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final bloodBankSearchProvider = FutureProvider.autoDispose
    .family<List<BloodBankModel>, BloodBankSearchParams>(
  (ref, params) async {
    final repository = ref.read(bloodBankRepositoryProvider);
    final response = await repository.getVerifiedBloodBanks(
      pageSize: 50,
      search: _trimOrNull(params.query),
      city: _trimOrNull(params.city),
      pincode: _trimOrNull(params.pincode),
      area: _trimOrNull(params.area),
      bloodGroup: _trimOrNull(params.bloodGroup),
      componentType: _trimOrNull(params.componentType),
      available24x7: params.careFilter == BloodBankCareFilter.available24x7
          ? true
          : null,
      emergencySupply: params.careFilter == BloodBankCareFilter.emergencySupply
          ? true
          : null,
      homeDelivery: params.careFilter == BloodBankCareFilter.homeDelivery
          ? true
          : null,
      openNow: params.careFilter == BloodBankCareFilter.openNow ? true : null,
      hasDiscount: params.careFilter == BloodBankCareFilter.hasDiscount
          ? true
          : null,
      latitude: params.latitude,
      longitude: params.longitude,
      maxDistanceKm: params.maxDistanceKm,
      maxPrice: params.maxPrice,
      minRating: params.minRating,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Search failed');
  },
);

final bloodBankDetailProvider = FutureProvider.autoDispose
    .family<BloodBankModel, String>((ref, bloodBankId) async {
  final repository = ref.read(bloodBankRepositoryProvider);
  final response = await repository.getBloodBankProfile(bloodBankId);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Failed to load blood bank');
});

final bloodBankReviewsProvider = FutureProvider.autoDispose
    .family<List<BloodReviewModel>, String>((ref, bloodBankId) async {
  final repository = ref.read(bloodBankRepositoryProvider);
  final response = await repository.getReviews(bloodBankId);
  if (response.success && response.data != null) {
    return response.data!;
  }
  return [];
});
