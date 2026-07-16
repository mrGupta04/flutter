import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/doctor_feedback_model.dart';
import '../../../data/repositories/nurse_feedback_repository.dart';

final nurseFeedbackRepositoryProvider = Provider(
  (ref) => NurseFeedbackRepository(),
);

final nurseFeedbackProvider =
    FutureProvider.family<DoctorFeedbackSummary, String>((ref, nurseId) async {
  final repository = ref.watch(nurseFeedbackRepositoryProvider);
  final response = await repository.getNurseFeedback(nurseId: nurseId);

  if (response.success && response.data != null) {
    return response.data!;
  }

  throw Exception(response.error ?? 'Failed to load feedback');
});
