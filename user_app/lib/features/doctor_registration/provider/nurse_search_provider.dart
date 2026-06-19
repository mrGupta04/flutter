import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

/// Nurse listing filter: all, home visit only, or shift/on-site care.
enum NurseCareFilter {
  all('All nurses'),
  homeVisit('Home visit'),
  shiftCare('Shift / on-site');

  const NurseCareFilter(this.label);
  final String label;
}

class NurseSearchParams {
  const NurseSearchParams({
    this.query,
    this.city,
    this.specialization,
    this.careFilter = NurseCareFilter.all,
  });

  final String? query;
  final String? city;
  final String? specialization;
  final NurseCareFilter careFilter;

  bool get hasTextFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      (specialization != null && specialization!.trim().isNotEmpty);

  bool? get homeVisit =>
      careFilter == NurseCareFilter.homeVisit ? true : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NurseSearchParams &&
        other.query == query &&
        other.city == city &&
        other.specialization == specialization &&
        other.careFilter == careFilter;
  }

  @override
  int get hashCode => Object.hash(query, city, specialization, careFilter);
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final nurseSearchProvider =
    FutureProvider.autoDispose.family<List<NurseModel>, NurseSearchParams>(
  (ref, params) async {
    final repository = NurseRegistrationRepository();
    final response = await repository.getVerifiedNurses(
      pageSize: 50,
      search: _trimOrNull(params.query),
      city: _trimOrNull(params.city),
      specialization: _trimOrNull(params.specialization),
      homeVisit: params.homeVisit,
    );

    if (response.success && response.data != null) {
      var nurses = response.data!;
      if (params.careFilter == NurseCareFilter.shiftCare) {
        nurses = nurses
            .where((n) => n.availableForHomeVisit != true)
            .toList(growable: false);
      }
      return nurses;
    }

    throw Exception(response.error ?? 'Search failed');
  },
);
