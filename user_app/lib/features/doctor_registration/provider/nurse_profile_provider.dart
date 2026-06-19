import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

final nurseProfileProvider =
    FutureProvider.autoDispose.family<NurseModel, String>((ref, nurseId) async {
  if (nurseId.isEmpty) {
    throw Exception('Nurse id is required');
  }
  final repository = NurseRegistrationRepository();
  final response = await repository.getPublicProfile(nurseId: nurseId);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Failed to load nurse profile');
});
