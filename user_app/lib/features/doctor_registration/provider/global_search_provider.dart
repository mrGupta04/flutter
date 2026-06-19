import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/models/doctor_model.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/ambulance_repository.dart';
import '../../../data/repositories/blood_bank_repository.dart';
import '../../../data/repositories/nurse_registration_repository.dart';
import 'doctor_registration_repository_provider.dart';

/// Combined marketplace search results across all provider types.
class GlobalSearchResults {
  const GlobalSearchResults({
    this.doctors = const [],
    this.nurses = const [],
    this.ambulances = const [],
    this.bloodBanks = const [],
  });

  final List<DoctorModel> doctors;
  final List<NurseModel> nurses;
  final List<AmbulanceModel> ambulances;
  final List<BloodBankModel> bloodBanks;

  static const empty = GlobalSearchResults();

  int get totalCount =>
      doctors.length + nurses.length + ambulances.length + bloodBanks.length;

  bool get isEmpty => totalCount == 0;
}

final globalSearchProvider =
    FutureProvider.autoDispose.family<GlobalSearchResults, String>(
  (ref, rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return GlobalSearchResults.empty;

    final doctorRepo = ref.watch(doctorRegistrationRepositoryProvider);
    final nurseRepo = NurseRegistrationRepository();
    final ambulanceRepo = AmbulanceRepository();
    final bloodBankRepo = BloodBankRepository();

    final doctorResponse = await doctorRepo.getVerifiedDoctors(
      pageSize: 30,
      query: query,
    );
    final nurseResponse = await nurseRepo.getVerifiedNurses(
      pageSize: 30,
      search: query,
    );
    final ambulanceResponse = await ambulanceRepo.getVerifiedAmbulances(
      pageSize: 30,
      search: query,
    );
    final bloodBankResponse = await bloodBankRepo.getVerifiedBloodBanks(
      pageSize: 30,
      search: query,
    );

    if (!doctorResponse.success &&
        !nurseResponse.success &&
        !ambulanceResponse.success &&
        !bloodBankResponse.success) {
      throw Exception(
        doctorResponse.error ??
            nurseResponse.error ??
            'Search failed. Check your connection.',
      );
    }

    return GlobalSearchResults(
      doctors: doctorResponse.data ?? [],
      nurses: nurseResponse.data ?? [],
      ambulances: ambulanceResponse.data ?? [],
      bloodBanks: bloodBankResponse.data ?? [],
    );
  },
);
