import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repositories.dart';

/// Repository access for verified doctor listings (user marketplace).
final doctorRegistrationRepositoryProvider = Provider((ref) {
  return DoctorRegistrationRepository();
});
