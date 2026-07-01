import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/scan_center_model.dart';
import '../../../data/repositories/scan_registration_repository.dart';

final scanRegistrationRepositoryProvider = Provider(
  (ref) => ScanRegistrationRepository(),
);

class ScanRegistrationState {
  const ScanRegistrationState({
    this.center,
    this.isSubmitting = false,
    this.error,
  });

  final ScanCenterModel? center;
  final bool isSubmitting;
  final String? error;

  ScanRegistrationState copyWith({
    ScanCenterModel? center,
    bool? isSubmitting,
    String? error,
  }) {
    return ScanRegistrationState(
      center: center ?? this.center,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class ScanRegistrationNotifier extends StateNotifier<ScanRegistrationState> {
  ScanRegistrationNotifier(this.repository)
      : super(const ScanRegistrationState());

  final ScanRegistrationRepository repository;

  void setScanCenter(ScanCenterModel center) {
    state = state.copyWith(center: center);
  }

  Future<void> refreshScanCenterFromApi({String? scanCenterId}) async {
    final response = await repository.getProfile(scanCenterId: scanCenterId);
    if (response.success && response.data != null) {
      final center = response.data!;
      state = state.copyWith(center: center);
      final id = center.id;
      if (id != null && id.isNotEmpty) {
        await TokenStorage.instance.saveScanCenterId(id);
      }
    }
  }

  Future<bool> submit(
    ScanCenterModel center, {
    String? password,
    Uint8List? logoBytes,
    String? logoFileName,
    List<({Uint8List bytes, String filename, String type, String label})>?
        pendingDocuments,
    List<({Uint8List bytes, String filename})>? pendingImages,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    var model = center;
    final centerId = center.id;
    if (centerId == null) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Scan center id is required',
      );
      return false;
    }

    if (logoBytes != null) {
      final upload = await repository.uploadProfilePicture(
        scanCenterId: centerId,
        bytes: logoBytes,
        filename: logoFileName ?? 'logo.jpg',
        mobileNumber: center.mobileNumber,
      );
      if (!upload.success || upload.data == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: upload.error ?? 'Failed to upload center logo.',
        );
        return false;
      }
      model = model.copyWith(profilePicture: upload.data);
    }

    final docs = <ScanCenterDocument>[...(model.documents ?? const [])];
    for (final doc in pendingDocuments ?? const []) {
      final upload = await repository.uploadDocument(
        scanCenterId: centerId,
        bytes: doc.bytes,
        type: doc.type,
        label: doc.label,
        filename: doc.filename,
        mobileNumber: center.mobileNumber,
      );
      if (upload.success && upload.data != null) {
        docs.add(upload.data!);
      }
    }

    final images = <String>[...(model.centerImages ?? const [])];
    for (final img in pendingImages ?? const []) {
      final upload = await repository.uploadCenterImage(
        scanCenterId: centerId,
        bytes: img.bytes,
        filename: img.filename,
        mobileNumber: center.mobileNumber,
      );
      if (upload.success && upload.data != null) {
        images.add(upload.data!);
      }
    }

    model = model.copyWith(documents: docs, centerImages: images);

    final response = await repository.register(model, password: password);
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isSubmitting: false);
      return true;
    }
    state = state.copyWith(
      isSubmitting: false,
      error: response.error ?? 'Registration failed',
    );
    return false;
  }

  Future<bool> updateProfile(ScanCenterModel center) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final response = await repository.updateProfile(center);
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isSubmitting: false);
      return true;
    }
    state = state.copyWith(
      isSubmitting: false,
      error: response.error ?? 'Update failed',
    );
    return false;
  }
}

final scanRegistrationProvider =
    StateNotifierProvider<ScanRegistrationNotifier, ScanRegistrationState>(
  (ref) => ScanRegistrationNotifier(ref.watch(scanRegistrationRepositoryProvider)),
);
