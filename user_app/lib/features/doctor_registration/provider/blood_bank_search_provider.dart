import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/repositories/blood_bank_repository.dart';

enum BloodBankCareFilter {
  all('All blood banks'),
  available24x7('24x7 only'),
  apheresis('Apheresis');

  const BloodBankCareFilter(this.label);
  final String label;
}

class BloodBankSearchParams {
  const BloodBankSearchParams({
    this.query,
    this.city,
    this.bloodGroup,
    this.careFilter = BloodBankCareFilter.all,
  });

  final String? query;
  final String? city;
  final String? bloodGroup;
  final BloodBankCareFilter careFilter;

  bool get hasTextFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      (bloodGroup != null && bloodGroup!.trim().isNotEmpty);

  bool? get available24x7 =>
      careFilter == BloodBankCareFilter.available24x7 ? true : null;

  bool? get hasApheresis =>
      careFilter == BloodBankCareFilter.apheresis ? true : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodBankSearchParams &&
        other.query == query &&
        other.city == city &&
        other.bloodGroup == bloodGroup &&
        other.careFilter == careFilter;
  }

  @override
  int get hashCode => Object.hash(query, city, bloodGroup, careFilter);
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final bloodBankSearchProvider = FutureProvider.autoDispose
    .family<List<BloodBankModel>, BloodBankSearchParams>(
  (ref, params) async {
    final repository = BloodBankRepository();
    final response = await repository.getVerifiedBloodBanks(
      pageSize: 50,
      search: _trimOrNull(params.query),
      city: _trimOrNull(params.city),
      bloodGroup: _trimOrNull(params.bloodGroup),
      available24x7: params.available24x7,
      hasApheresis: params.hasApheresis,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.error ?? 'Search failed');
  },
);
