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
  BloodBankRegistrationNotifier(this.repository)
      : super(BloodBankRegistrationState());

  final BloodBankRegistrationRepository repository;

  Future<bool> submit(
    BloodBankModel bloodBank, {
    String? password,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
    Uint8List? logoBytes,
    String? logoFileName,
    List<({Uint8List bytes, String filename, String type, String label})>?
        pendingDocuments,
    List<({Uint8List bytes, String filename})>? pendingGalleryImages,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    var model = bloodBank;
    final bloodBankId = bloodBank.id;
    if (bloodBankId == null) {
      state = state.copyWith(isSubmitting: false, error: 'Blood bank id is required');
      return false;
    }

    if (profileImageBytes != null) {
      final upload = await repository.uploadProfilePicture(
        bloodBankId: bloodBankId,
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
      model = model.copyWith(profilePicture: upload.data);
    }

    if (logoBytes != null) {
      final upload = await repository.uploadLogo(
        bloodBankId: bloodBankId,
        bytes: logoBytes,
        filename: logoFileName ?? 'logo.jpg',
      );
      if (upload.success && upload.data != null) {
        model = model.copyWith(logoUrl: upload.data);
      }
    }

    final docs = <BloodBankDocument>[...(model.documents ?? const [])];
    for (final doc in pendingDocuments ?? const []) {
      final upload = await repository.uploadDocument(
        bloodBankId: bloodBankId,
        bytes: doc.bytes,
        type: doc.type,
        label: doc.label,
        filename: doc.filename,
        mobileNumber: bloodBank.mobileNumber,
      );
      if (upload.success && upload.data != null) {
        docs.add(upload.data!);
      }
    }

    final images = <String>[...(model.galleryImages ?? const [])];
    for (final img in pendingGalleryImages ?? const []) {
      final upload = await repository.uploadGalleryImage(
        bloodBankId: bloodBankId,
        bytes: img.bytes,
        filename: img.filename,
      );
      if (upload.success && upload.data != null) {
        images.add(upload.data!);
      }
    }

    model = model.copyWith(documents: docs, galleryImages: images);

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
