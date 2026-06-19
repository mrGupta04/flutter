import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/doctor_feedback_model.dart';
import '../../../data/repositories/doctor_feedback_repository.dart';

final doctorFeedbackRepositoryProvider = Provider(
  (ref) => DoctorFeedbackRepository(),
);

final doctorFeedbackProvider =
    FutureProvider.family<DoctorFeedbackSummary, String>((ref, doctorId) async {
  final repository = ref.watch(doctorFeedbackRepositoryProvider);
  final response = await repository.getDoctorFeedback(doctorId: doctorId);

  if (response.success && response.data != null) {
    return response.data!;
  }

  throw Exception(response.error ?? 'Failed to load feedback');
});
