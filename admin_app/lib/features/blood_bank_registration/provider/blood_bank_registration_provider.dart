import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/repositories/blood_bank_registration_repository.dart';

final bloodBankRegistrationRepositoryProvider = Provider(
  (ref) => BloodBankRegistrationRepository(),
);

class BloodBankRegistrationState {
  final BloodBankModel? bloodBank;
  final bool isSubmitting;
  final String? error;

  BloodBankRegistrationState({
    this.bloodBank,
    this.isSubmitting = false,
    this.error,
  });

  BloodBankRegistrationState copyWith({
    BloodBankModel? bloodBank,
    bool? isSubmitting,
    String? error,
  }) {
    return BloodBankRegistrationState(
      bloodBank: bloodBank ?? this.bloodBank,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class BloodBankRegistrationNotifier
    extends StateNotifier<BloodBankRegistrationState> {
  final BloodBankRegistrationRepository repository;

  BloodBankRegistrationNotifier(this.repository)
      : super(BloodBankRegistrationState());

  Future<bool> submit(
    BloodBankModel bloodBank, {
    String? password,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    var model = bloodBank;
    if (profileImageBytes != null && bloodBank.id != null) {
      final upload = await repository.uploadProfilePicture(
        bloodBankId: bloodBank.id!,
        bytes: profileImageBytes,
        filename: profileImageFileName ?? 'profile.jpg',
        mobileNumber: bloodBank.mobileNumber,
      );
      if (!upload.success || upload.data == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: upload.error ?? 'Failed to upload profile picture.',
        );
        return false;
      }
      model = bloodBank.copyWith(profilePicture: upload.data);
    }

    final response = await repository.register(model, password: password);
    if (response.success && response.data != null) {
      state = state.copyWith(bloodBank: response.data, isSubmitting: false);
      return true;
    }
    state = state.copyWith(
      isSubmitting: false,
      error: response.error ?? 'Registration failed',
    );
    return false;
  }

  Future<void> refreshFromApi({String? bloodBankId}) async {
    final response = await repository.getProfile(bloodBankId: bloodBankId);
    if (response.success && response.data != null) {
      state = state.copyWith(bloodBank: response.data);
    }
  }

  void setBloodBank(BloodBankModel bloodBank) {
    state = state.copyWith(bloodBank: bloodBank);
  }
}

final bloodBankRegistrationProvider = StateNotifierProvider<
    BloodBankRegistrationNotifier, BloodBankRegistrationState>((ref) {
  return BloodBankRegistrationNotifier(
    ref.watch(bloodBankRegistrationRepositoryProvider),
  );
});
