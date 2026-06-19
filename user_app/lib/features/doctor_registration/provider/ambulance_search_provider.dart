import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../data/repositories/ambulance_repository.dart';

enum AmbulanceCareFilter {
  all('All services'),
  available24x7('24x7 only');

  const AmbulanceCareFilter(this.label);
  final String label;
}

class AmbulanceSearchParams {
  const AmbulanceSearchParams({
    this.query,
    this.city,
    this.vehicleType,
    this.careFilter = AmbulanceCareFilter.all,
  });

  final String? query;
  final String? city;
  final String? vehicleType;
  final AmbulanceCareFilter careFilter;

  bool get hasTextFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      (vehicleType != null && vehicleType!.trim().isNotEmpty);

  bool? get available24x7 =>
      careFilter == AmbulanceCareFilter.available24x7 ? true : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmbulanceSearchParams &&
        other.query == query &&
        other.city == city &&
        other.vehicleType == vehicleType &&
        other.careFilter == careFilter;
  }

  @override
  int get hashCode => Object.hash(query, city, vehicleType, careFilter);
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final ambulanceSearchProvider = FutureProvider.autoDispose
    .family<List<AmbulanceModel>, AmbulanceSearchParams>(
  (ref, params) async {
    final repository = AmbulanceRepository();
    final response = await repository.getVerifiedAmbulances(
      pageSize: 50,
      search: _trimOrNull(params.query),
      city: _trimOrNull(params.city),
      vehicleType: _trimOrNull(params.vehicleType),
      available24x7: params.available24x7,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.error ?? 'Search failed');
  },
);
