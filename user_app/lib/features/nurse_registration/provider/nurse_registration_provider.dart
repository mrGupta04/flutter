import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

final nurseRegistrationRepositoryProvider = Provider(
  (ref) => NurseRegistrationRepository(),
);

class NurseRegistrationState {
  final NurseModel? nurse;
  final bool isSubmitting;
  final String? error;

  NurseRegistrationState({
    this.nurse,
    this.isSubmitting = false,
    this.error,
  });

  NurseRegistrationState copyWith({
    NurseModel? nurse,
    bool? isSubmitting,
    String? error,
  }) {
    return NurseRegistrationState(
      nurse: nurse ?? this.nurse,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class NurseRegistrationNotifier extends StateNotifier<NurseRegistrationState> {
  final NurseRegistrationRepository repository;

  NurseRegistrationNotifier(this.repository) : super(NurseRegistrationState());

  Future<bool> submit(
    NurseModel nurse, {
    Uint8List? profileImageBytes,
    String? profileImageFileName,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    var model = nurse;
    if (profileImageBytes != null && nurse.id != null) {
      final upload = await repository.uploadProfilePicture(
        nurseId: nurse.id!,
        bytes: profileImageBytes,
        filename: profileImageFileName ?? 'profile.jpg',
        mobileNumber: nurse.mobileNumber,
      );
      if (!upload.success || upload.data == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: upload.error ?? 'Failed to upload profile picture.',
        );
        return false;
      }
      model = nurse.copyWith(profilePicture: upload.data);
    }

    final response = await repository.register(model);
    if (response.success && response.data != null) {
      state = state.copyWith(nurse: response.data, isSubmitting: false);
      return true;
    }
    state = state.copyWith(
      isSubmitting: false,
      error: response.error ?? 'Registration failed',
    );
    return false;
  }

  Future<void> refreshFromApi({String? nurseId}) async {
    final response = await repository.getProfile(nurseId: nurseId);
    if (response.success && response.data != null) {
      state = state.copyWith(nurse: response.data);
    }
  }
}

final nurseRegistrationProvider =
    StateNotifierProvider<NurseRegistrationNotifier, NurseRegistrationState>(
  (ref) {
    final repository = ref.watch(nurseRegistrationRepositoryProvider);
    return NurseRegistrationNotifier(repository);
  },
);
