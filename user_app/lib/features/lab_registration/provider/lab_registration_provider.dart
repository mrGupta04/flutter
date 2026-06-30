import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/repositories/lab_registration_repository.dart';

final labRegistrationRepositoryProvider = Provider(
  (ref) => LabRegistrationRepository(),
);

class LabRegistrationState {
  const LabRegistrationState({
    this.lab,
    this.isSubmitting = false,
    this.error,
  });

  final LabModel? lab;
  final bool isSubmitting;
  final String? error;

  LabRegistrationState copyWith({
    LabModel? lab,
    bool? isSubmitting,
    String? error,
  }) {
    return LabRegistrationState(
      lab: lab ?? this.lab,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class LabRegistrationNotifier extends StateNotifier<LabRegistrationState> {
  LabRegistrationNotifier(this.repository) : super(const LabRegistrationState());

  final LabRegistrationRepository repository;

  Future<bool> submit(
    LabModel lab, {
    String? password,
    Uint8List? logoBytes,
    String? logoFileName,
    List<({Uint8List bytes, String filename, String type, String label})>?
        pendingDocuments,
    List<({Uint8List bytes, String filename})>? pendingImages,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    var model = lab;
    final labId = lab.id;
    if (labId == null) {
      state = state.copyWith(isSubmitting: false, error: 'Lab id is required');
      return false;
    }

    if (logoBytes != null) {
      final upload = await repository.uploadProfilePicture(
        labId: labId,
        bytes: logoBytes,
        filename: logoFileName ?? 'logo.jpg',
        mobileNumber: lab.mobileNumber,
      );
      if (!upload.success || upload.data == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: upload.error ?? 'Failed to upload lab logo.',
        );
        return false;
      }
      model = model.copyWith(profilePicture: upload.data);
    }

    final docs = <LabDocument>[...(model.documents ?? const [])];
    for (final doc in pendingDocuments ?? const []) {
      final upload = await repository.uploadDocument(
        labId: labId,
        bytes: doc.bytes,
        type: doc.type,
        label: doc.label,
        filename: doc.filename,
        mobileNumber: lab.mobileNumber,
      );
      if (upload.success && upload.data != null) {
        docs.add(upload.data!);
      }
    }

    final images = <String>[...(model.labImages ?? const [])];
    for (final img in pendingImages ?? const []) {
      final upload = await repository.uploadLabImage(
        labId: labId,
        bytes: img.bytes,
        filename: img.filename,
        mobileNumber: lab.mobileNumber,
      );
      if (upload.success && upload.data != null) {
        images.add(upload.data!);
      }
    }

    model = model.copyWith(documents: docs, labImages: images);

    final response = await repository.register(model, password: password);
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isSubmitting: false);
      return true;
    }
    state = state.copyWith(
      isSubmitting: false,
      error: response.error ?? 'Registration failed',
    );
    return false;
  }
}

final labRegistrationProvider =
    StateNotifierProvider<LabRegistrationNotifier, LabRegistrationState>((ref) {
  return LabRegistrationNotifier(ref.watch(labRegistrationRepositoryProvider));
});
