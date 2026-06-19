import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

final verifiedNursesProvider =
    FutureProvider.autoDispose<List<NurseModel>>((ref) async {
  final repository = NurseRegistrationRepository();
  final response = await repository.getVerifiedNurses();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Failed to load nurses');
});
