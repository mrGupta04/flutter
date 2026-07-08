import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/doctor_availability_constants.dart';
import '../../../core/constants/phone_countries.dart';
import '../../../core/services/token_storage.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';

enum _AvailabilitySlotType { online, clinic, home }

/// Provider for DoctorRegistrationRepository
final doctorRegistrationRepositoryProvider = Provider((ref) {
  return DoctorRegistrationRepository();
});

/// State for doctor registration submission
class DoctorRegistrationState {
  final DoctorModel? doctor;
  final bool isLoading;
  final String? error;
  final bool? success;

  DoctorRegistrationState({
    this.doctor,
    this.isLoading = false,
    this.error,
    this.success,
  });

  DoctorRegistrationState copyWith({
    DoctorModel? doctor,
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return DoctorRegistrationState(
      doctor: doctor ?? this.doctor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Notifier for doctor registration submission
class DoctorRegistrationNotifier extends StateNotifier<DoctorRegistrationState> {
  DoctorRegistrationNotifier(this.repository) : super(DoctorRegistrationState());

  final DoctorRegistrationRepository repository;

  void updateDoctorData(DoctorModel updatedDoctor) {
    state = state.copyWith(
      doctor: updatedDoctor,
      error: null,
    );
  }

  /// Refresh doctor from API (e.g. after admin approval).
  Future<void> refreshDoctorFromApi({String? doctorId}) async {
    final response = await repository.getDoctorProfile(doctorId: doctorId);
    if (response.success && response.data != null) {
      updateDoctorData(response.data!);
      final id = response.data!.id;
      if (id != null && id.isNotEmpty) {
        await TokenStorage.instance.saveDoctorId(id);
      }
    }
  }

  Future<bool> submitRegistration(DoctorModel doctor) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await repository.registerDoctor(doctor: doctor);
      if (response.success && response.data != null) {
        state = state.copyWith(
          doctor: response.data,
          isLoading: false,
          success: true,
          error: null,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: response.error ?? 'Failed to submit registration',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: 'An error occurred while submitting registration',
      );
      return false;
    }
  }

  void resetState() {
    state = DoctorRegistrationState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for doctor registration notifier
final doctorRegistrationProvider =
    StateNotifierProvider<DoctorRegistrationNotifier, DoctorRegistrationState>((ref) {
  final repository = ref.watch(doctorRegistrationRepositoryProvider);
  return DoctorRegistrationNotifier(repository);
});

/// Registration form state
class RegistrationFormState {
  final String draftId;
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profileImagePath;
  final Uint8List? profileImageBytes;
  final String? profileImageFileName;
  final String mobileNumber;
  final String countryCode;
  final String aadhaarNumber;
  final bool emailVerified;
  final String verifiedEmail;
  final bool isSendingEmailOtp;
  final bool isVerifyingEmailOtp;
  final String? emailVerificationError;
  final String? emailVerificationMessage;

  final String medicalRegistrationNumber;
  final String medicalCouncilName;
  final List<String> specializations;
  final String qualification;
  final String yearsOfExperience;
  final String clinicName;
  final String onlineConsultFee;
  final String homeVisitFee;
  final String visitSiteFee;
  final List<String> languagesSpoken;
  final String bio;
  final bool offersOnlineConsult;
  final bool offersBookHome;
  final bool offersVisitSite;

  final String address;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;

  final PayoutMethod payoutMethod;
  final String bankAccountNumber;
  final String ifscCode;
  final String upiId;

  final Map<DocumentType, String> documentPaths;
  final Map<DocumentType, Uint8List> documentBytes;
  final Map<DocumentType, String> documentFileNames;
  final Map<DocumentType, double> uploadProgress;
  final Map<DocumentType, DoctorDocumentModel> uploadedDocuments;

  final Map<int, Uint8List> hospitalPhotoBytes;
  final Map<int, String> hospitalPhotoFileNames;
  final Map<int, String> hospitalPhotoUrls;
  final Map<int, double> hospitalPhotoUploadProgress;

  final bool isSubmitting;
  final String? submitError;
  final Set<String> selectedOnlineAvailabilitySlots;
  final Set<String> selectedClinicAvailabilitySlots;
  final Set<String> selectedHomeAvailabilitySlots;

  RegistrationFormState({
    required this.draftId,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.gender,
    this.dateOfBirth,
    this.profileImagePath,
    this.profileImageBytes,
    this.profileImageFileName,
    this.mobileNumber = '',
    this.countryCode = PhoneCountries.defaultDialCode,
    this.aadhaarNumber = '',
    this.emailVerified = false,
    this.verifiedEmail = '',
    this.isSendingEmailOtp = false,
    this.isVerifyingEmailOtp = false,
    this.emailVerificationError,
    this.emailVerificationMessage,
    this.medicalRegistrationNumber = '',
    this.medicalCouncilName = '',
    this.specializations = const [],
    this.qualification = '',
    this.yearsOfExperience = '',
    this.clinicName = '',
    this.onlineConsultFee = '',
    this.homeVisitFee = '',
    this.visitSiteFee = '',
    this.languagesSpoken = const ['English'],
    this.bio = '',
    this.offersOnlineConsult = false,
    this.offersBookHome = false,
    this.offersVisitSite = false,
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.payoutMethod = PayoutMethod.bank,
    this.bankAccountNumber = '',
    this.ifscCode = '',
    this.upiId = '',
    this.documentPaths = const {},
    this.documentBytes = const {},
    this.documentFileNames = const {},
    this.uploadProgress = const {},
    this.uploadedDocuments = const {},
    this.hospitalPhotoBytes = const {},
    this.hospitalPhotoFileNames = const {},
    this.hospitalPhotoUrls = const {},
    this.hospitalPhotoUploadProgress = const {},
    this.isSubmitting = false,
    this.submitError,
    this.selectedOnlineAvailabilitySlots = const {},
    this.selectedClinicAvailabilitySlots = const {},
    this.selectedHomeAvailabilitySlots = const {},
  });

  int get selectedOnlineAvailabilityCount =>
      selectedOnlineAvailabilitySlots.length;

  int get selectedClinicAvailabilityCount =>
      selectedClinicAvailabilitySlots.length;

  int get selectedHomeAvailabilityCount =>
      selectedHomeAvailabilitySlots.length;

  factory RegistrationFormState.initial() {
    return RegistrationFormState(draftId: const Uuid().v4());
  }

  String get aadhaarMaskedDisplay {
    if (aadhaarNumber.length >= 4) {
      return 'XXXX-XXXX-${aadhaarNumber.substring(aadhaarNumber.length - 4)}';
    }
    return aadhaarNumber.isEmpty ? '-' : aadhaarNumber;
  }

  bool get hasProfileImage =>
      profileImageBytes != null ||
      (profileImagePath != null && profileImagePath!.isNotEmpty);

  bool hasDocumentSelected(DocumentType type) =>
      documentBytes.containsKey(type) ||
      (documentPaths[type]?.isNotEmpty ?? false);

  bool get hasConsultationOptionSelected =>
      offersOnlineConsult || offersBookHome || offersVisitSite;

  bool get allHospitalPhotosUploaded => doctorHospitalPhotoSlots.every(
        (slot) => (hospitalPhotoUrls[slot]?.isNotEmpty ?? false),
      );

  int get uploadedHospitalPhotoCount => doctorHospitalPhotoSlots
      .where((slot) => (hospitalPhotoUrls[slot]?.isNotEmpty ?? false))
      .length;

  RegistrationFormState copyWith({
    String? draftId,
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImagePath,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
    String? mobileNumber,
    String? countryCode,
    String? aadhaarNumber,
    bool? emailVerified,
    String? verifiedEmail,
    bool? isSendingEmailOtp,
    bool? isVerifyingEmailOtp,
    String? emailVerificationError,
    String? emailVerificationMessage,
    String? medicalRegistrationNumber,
    String? medicalCouncilName,
    List<String>? specializations,
    String? qualification,
    String? yearsOfExperience,
    String? clinicName,
    String? onlineConsultFee,
    String? homeVisitFee,
    String? visitSiteFee,
    List<String>? languagesSpoken,
    String? bio,
    bool? offersOnlineConsult,
    bool? offersBookHome,
    bool? offersVisitSite,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    PayoutMethod? payoutMethod,
    String? bankAccountNumber,
    String? ifscCode,
    String? upiId,
    Map<DocumentType, String>? documentPaths,
    Map<DocumentType, Uint8List>? documentBytes,
    Map<DocumentType, String>? documentFileNames,
    Map<DocumentType, double>? uploadProgress,
    Map<DocumentType, DoctorDocumentModel>? uploadedDocuments,
    Map<int, Uint8List>? hospitalPhotoBytes,
    Map<int, String>? hospitalPhotoFileNames,
    Map<int, String>? hospitalPhotoUrls,
    Map<int, double>? hospitalPhotoUploadProgress,
    bool? isSubmitting,
    String? submitError,
    Set<String>? selectedOnlineAvailabilitySlots,
    Set<String>? selectedClinicAvailabilitySlots,
    Set<String>? selectedHomeAvailabilitySlots,
  }) {
    return RegistrationFormState(
      draftId: draftId ?? this.draftId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      profileImageBytes: profileImageBytes ?? this.profileImageBytes,
      profileImageFileName: profileImageFileName ?? this.profileImageFileName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      countryCode: countryCode ?? this.countryCode,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      isSendingEmailOtp: isSendingEmailOtp ?? this.isSendingEmailOtp,
      isVerifyingEmailOtp: isVerifyingEmailOtp ?? this.isVerifyingEmailOtp,
      emailVerificationError: emailVerificationError,
      emailVerificationMessage: emailVerificationMessage,
      medicalRegistrationNumber:
          medicalRegistrationNumber ?? this.medicalRegistrationNumber,
      medicalCouncilName: medicalCouncilName ?? this.medicalCouncilName,
      specializations: specializations ?? this.specializations,
      qualification: qualification ?? this.qualification,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      clinicName: clinicName ?? this.clinicName,
      onlineConsultFee: onlineConsultFee ?? this.onlineConsultFee,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      visitSiteFee: visitSiteFee ?? this.visitSiteFee,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      bio: bio ?? this.bio,
      offersOnlineConsult: offersOnlineConsult ?? this.offersOnlineConsult,
      offersBookHome: offersBookHome ?? this.offersBookHome,
      offersVisitSite: offersVisitSite ?? this.offersVisitSite,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      documentPaths: documentPaths ?? this.documentPaths,
      documentBytes: documentBytes ?? this.documentBytes,
      documentFileNames: documentFileNames ?? this.documentFileNames,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      hospitalPhotoBytes: hospitalPhotoBytes ?? this.hospitalPhotoBytes,
      hospitalPhotoFileNames:
          hospitalPhotoFileNames ?? this.hospitalPhotoFileNames,
      hospitalPhotoUrls: hospitalPhotoUrls ?? this.hospitalPhotoUrls,
      hospitalPhotoUploadProgress:
          hospitalPhotoUploadProgress ?? this.hospitalPhotoUploadProgress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      selectedOnlineAvailabilitySlots: selectedOnlineAvailabilitySlots ??
          this.selectedOnlineAvailabilitySlots,
      selectedClinicAvailabilitySlots: selectedClinicAvailabilitySlots ??
          this.selectedClinicAvailabilitySlots,
      selectedHomeAvailabilitySlots: selectedHomeAvailabilitySlots ??
          this.selectedHomeAvailabilitySlots,
    );
  }
}

/// Notifier for registration form data
class RegistrationFormNotifier extends StateNotifier<RegistrationFormState> {
  RegistrationFormNotifier(this._ref, this._repository)
      : super(RegistrationFormState.initial());

  final Ref _ref;
  final DoctorRegistrationRepository _repository;

  void updateAadhaarNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(
      aadhaarNumber: digits.length > 12 ? digits.substring(0, 12) : digits,
    );
  }

  void updatePersonalInfo({
    String? fullName,
    String? email,
    String? mobileNumber,
    String? countryCode,
    String? password,
    String? confirmPassword,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImagePath,
  }) {
    final normalizedEmail = email?.trim();
    var emailVerified = state.emailVerified;
    var verifiedEmail = state.verifiedEmail;

    if (normalizedEmail != null &&
        verifiedEmail.isNotEmpty &&
        normalizedEmail.toLowerCase() != verifiedEmail.toLowerCase()) {
      emailVerified = AppConstants.skipVerification;
      verifiedEmail = AppConstants.skipVerification ? normalizedEmail : '';
    } else if (AppConstants.skipVerification &&
        normalizedEmail != null &&
        ValidationUtils.validateEmail(normalizedEmail) == null) {
      emailVerified = true;
      verifiedEmail = normalizedEmail;
    }

    state = state.copyWith(
      fullName: fullName,
      email: normalizedEmail ?? email,
      mobileNumber: mobileNumber,
      countryCode: countryCode,
      password: password,
      confirmPassword: confirmPassword,
      gender: gender,
      dateOfBirth: dateOfBirth,
      profileImagePath: profileImagePath,
      emailVerified: emailVerified,
      verifiedEmail: verifiedEmail,
      emailVerificationError: null,
      emailVerificationMessage: null,
    );
  }

  Future<bool> sendEmailVerificationOtp() async {
    if (AppConstants.skipVerification) {
      final email = state.email.trim();
      if (ValidationUtils.validateEmail(email) != null) {
        state = state.copyWith(
          emailVerificationError: 'Enter a valid email address first.',
        );
        return false;
      }
      state = state.copyWith(
        emailVerified: true,
        verifiedEmail: email,
        emailVerificationMessage: 'Email verification skipped (dev mode).',
        emailVerificationError: null,
      );
      return true;
    }

    final email = state.email.trim();
    if (ValidationUtils.validateEmail(email) != null) {
      state = state.copyWith(
        emailVerificationError: 'Enter a valid email address first.',
      );
      return false;
    }

    state = state.copyWith(
      isSendingEmailOtp: true,
      emailVerificationError: null,
      emailVerificationMessage: null,
    );

    final response = await _repository.sendEmailVerificationOtp(
      doctorId: state.draftId,
      email: email,
    );

    if (response.success) {
      final maskedEmail = response.data?['maskedEmail'] as String?;
      final devOtp = response.data?['devOtp'] as String?;
      final message = devOtp != null && devOtp.isNotEmpty
          ? 'Dev verification code: $devOtp'
          : maskedEmail != null && maskedEmail.isNotEmpty
              ? 'Verification code sent to $maskedEmail. Check your inbox.'
              : (response.message ?? 'Verification code sent. Check your inbox.');
      state = state.copyWith(
        isSendingEmailOtp: false,
        emailVerificationMessage: message,
      );
      return true;
    }

    state = state.copyWith(
      isSendingEmailOtp: false,
      emailVerificationError: response.error ?? 'Failed to send verification code.',
    );
    return false;
  }

  Future<bool> verifyEmailVerificationOtp(String otp) async {
    if (AppConstants.skipVerification) {
      final email = state.email.trim();
      if (ValidationUtils.validateEmail(email) != null) {
        state = state.copyWith(
          emailVerificationError: 'Enter a valid email address first.',
        );
        return false;
      }
      state = state.copyWith(
        isVerifyingEmailOtp: false,
        emailVerified: true,
        verifiedEmail: email,
        emailVerificationMessage: 'Email verification skipped (dev mode).',
        emailVerificationError: null,
      );
      return true;
    }

    final email = state.email.trim();
    if (ValidationUtils.validateEmail(email) != null) {
      state = state.copyWith(
        emailVerificationError: 'Enter a valid email address first.',
      );
      return false;
    }
    if (otp.trim().length != 6) {
      state = state.copyWith(
        emailVerificationError: 'Enter the 6-digit verification code.',
      );
      return false;
    }

    state = state.copyWith(
      isVerifyingEmailOtp: true,
      emailVerificationError: null,
    );

    final response = await _repository.verifyEmailVerificationOtp(
      doctorId: state.draftId,
      email: email,
      otp: otp,
    );

    if (response.success) {
      state = state.copyWith(
        isVerifyingEmailOtp: false,
        emailVerified: true,
        verifiedEmail: email,
        emailVerificationMessage:
            response.message ?? 'Email verified successfully.',
        emailVerificationError: null,
      );
      return true;
    }

    state = state.copyWith(
      isVerifyingEmailOtp: false,
      emailVerificationError:
          response.error ?? 'Email verification failed. Please try again.',
    );
    return false;
  }

  void updateProfessionalDetails({
    String? medicalRegistrationNumber,
    String? medicalCouncilName,
    List<String>? specializations,
    String? qualification,
    String? yearsOfExperience,
    String? clinicName,
    String? onlineConsultFee,
    String? homeVisitFee,
    String? visitSiteFee,
    List<String>? languagesSpoken,
    String? bio,
    bool? offersOnlineConsult,
    bool? offersBookHome,
    bool? offersVisitSite,
  }) {
    state = state.copyWith(
      medicalRegistrationNumber: medicalRegistrationNumber,
      medicalCouncilName: medicalCouncilName,
      specializations: specializations,
      qualification: qualification,
      yearsOfExperience: yearsOfExperience,
      clinicName: clinicName,
      onlineConsultFee: onlineConsultFee,
      homeVisitFee: homeVisitFee,
      visitSiteFee: visitSiteFee,
      languagesSpoken: languagesSpoken,
      bio: bio,
      offersOnlineConsult: offersOnlineConsult,
      offersBookHome: offersBookHome,
      offersVisitSite: offersVisitSite,
    );
  }

  void setConsultationOptions({
    required bool online,
    required bool home,
    required bool visit,
  }) {
    state = state.copyWith(
      offersOnlineConsult: online,
      offersBookHome: home,
      offersVisitSite: visit,
      onlineConsultFee: online ? state.onlineConsultFee : '',
      homeVisitFee: home ? state.homeVisitFee : '',
      visitSiteFee: visit ? state.visitSiteFee : '',
    );
  }

  void updateConsultationFees({
    String? onlineConsultFee,
    String? homeVisitFee,
    String? visitSiteFee,
  }) {
    state = state.copyWith(
      onlineConsultFee: onlineConsultFee,
      homeVisitFee: homeVisitFee,
      visitSiteFee: visitSiteFee,
    );
  }

  void updateAddress({
    String? address,
    String? city,
    String? stateName,
    String? pincode,
  }) {
    state = state.copyWith(
      address: address,
      city: city,
      state: stateName,
      pincode: pincode,
    );
  }

  void setLocation({required double latitude, required double longitude}) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  void updateBankDetails({
    PayoutMethod? payoutMethod,
    String? bankAccountNumber,
    String? ifscCode,
    String? upiId,
  }) {
    state = state.copyWith(
      payoutMethod: payoutMethod,
      bankAccountNumber: bankAccountNumber,
      ifscCode: ifscCode != null
          ? ifscCode.replaceAll(RegExp(r'\s'), '').toUpperCase()
          : null,
      upiId: upiId != null ? upiId.trim().toLowerCase() : null,
    );
  }

  void setSpecializations(List<String> values) {
    state = state.copyWith(specializations: values);
  }

  void setLanguages(List<String> values) {
    state = state.copyWith(languagesSpoken: values);
  }

  void setProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) {
    state = state.copyWith(
      profileImageBytes: bytes,
      profileImageFileName: fileName,
      profileImagePath: null,
    );
  }

  void setHospitalPhoto({
    required int photoIndex,
    required Uint8List bytes,
    required String fileName,
  }) {
    final updatedBytes = Map<int, Uint8List>.from(state.hospitalPhotoBytes);
    final updatedNames = Map<int, String>.from(state.hospitalPhotoFileNames);
    updatedBytes[photoIndex] = bytes;
    updatedNames[photoIndex] = fileName;
    state = state.copyWith(
      hospitalPhotoBytes: updatedBytes,
      hospitalPhotoFileNames: updatedNames,
    );
  }

  Future<bool> uploadHospitalPhoto(int photoIndex) async {
    final bytes = state.hospitalPhotoBytes[photoIndex];
    final fileName = state.hospitalPhotoFileNames[photoIndex];

    if (bytes == null) {
      state = state.copyWith(
        submitError: 'Please select hospital photo $photoIndex.',
      );
      return false;
    }

    _setHospitalPhotoProgress(photoIndex, 0);

    try {
      final response = await _repository.uploadHospitalPhoto(
        doctorId: state.draftId,
        photoIndex: photoIndex,
        bytes: bytes,
        filename: fileName,
        mobileNumber: state.mobileNumber,
        onSendProgress: (sent, total) {
          if (total == 0) return;
          _setHospitalPhotoProgress(photoIndex, sent / total);
        },
      );

      if (response.success && response.data != null) {
        final updatedUrls = Map<int, String>.from(state.hospitalPhotoUrls);
        updatedUrls[photoIndex] = response.data!;
        _setHospitalPhotoProgress(photoIndex, 1);
        state = state.copyWith(
          hospitalPhotoUrls: updatedUrls,
          submitError: null,
        );
        await saveRegistrationDraft();
        return true;
      }

      state = state.copyWith(
        submitError: response.error ?? 'Failed to upload hospital photo.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        submitError: 'An error occurred while uploading hospital photo.',
      );
      return false;
    }
  }

  void setDocumentFile({
    required DocumentType type,
    required Uint8List bytes,
    required String fileName,
  }) {
    final updatedBytes = Map<DocumentType, Uint8List>.from(state.documentBytes);
    final updatedNames = Map<DocumentType, String>.from(state.documentFileNames);
    updatedBytes[type] = bytes;
    updatedNames[type] = fileName;
    state = state.copyWith(
      documentBytes: updatedBytes,
      documentFileNames: updatedNames,
    );
  }

  void setDocumentPath(DocumentType type, String path) {
    final updated = Map<DocumentType, String>.from(state.documentPaths);
    updated[type] = path;
    state = state.copyWith(documentPaths: updated);
  }

  void toggleOnlineAvailabilitySlot(int dayOfWeek, int startHour, bool selected) {
    _toggleAvailabilitySlot(
      slotType: _AvailabilitySlotType.online,
      dayOfWeek: dayOfWeek,
      startHour: startHour,
      selected: selected,
    );
  }

  void toggleClinicAvailabilitySlot(int dayOfWeek, int startHour, bool selected) {
    _toggleAvailabilitySlot(
      slotType: _AvailabilitySlotType.clinic,
      dayOfWeek: dayOfWeek,
      startHour: startHour,
      selected: selected,
    );
  }

  void toggleHomeAvailabilitySlot(int dayOfWeek, int startHour, bool selected) {
    _toggleAvailabilitySlot(
      slotType: _AvailabilitySlotType.home,
      dayOfWeek: dayOfWeek,
      startHour: startHour,
      selected: selected,
    );
  }

  void _toggleAvailabilitySlot({
    required _AvailabilitySlotType slotType,
    required int dayOfWeek,
    required int startHour,
    required bool selected,
  }) {
    final key = DoctorAvailabilityConstants.slotKey(dayOfWeek, startHour);
    var online = Set<String>.from(state.selectedOnlineAvailabilitySlots);
    var clinic = Set<String>.from(state.selectedClinicAvailabilitySlots);
    var home = Set<String>.from(state.selectedHomeAvailabilitySlots);

    if (selected) {
      switch (slotType) {
        case _AvailabilitySlotType.online:
          online.add(key);
          clinic.remove(key);
          home.remove(key);
        case _AvailabilitySlotType.clinic:
          clinic.add(key);
          online.remove(key);
          home.remove(key);
        case _AvailabilitySlotType.home:
          home.add(key);
          online.remove(key);
          clinic.remove(key);
      }
    } else {
      switch (slotType) {
        case _AvailabilitySlotType.online:
          online.remove(key);
        case _AvailabilitySlotType.clinic:
          clinic.remove(key);
        case _AvailabilitySlotType.home:
          home.remove(key);
      }
    }

    state = state.copyWith(
      selectedOnlineAvailabilitySlots: online,
      selectedClinicAvailabilitySlots: clinic,
      selectedHomeAvailabilitySlots: home,
      submitError: null,
    );
  }

  void clearDocument(DocumentType type) {
    final updatedPaths = Map<DocumentType, String>.from(state.documentPaths);
    final updatedBytes = Map<DocumentType, Uint8List>.from(state.documentBytes);
    final updatedNames = Map<DocumentType, String>.from(state.documentFileNames);
    final updatedUploads = Map<DocumentType, DoctorDocumentModel>.from(
      state.uploadedDocuments,
    );
    final updatedProgress = Map<DocumentType, double>.from(state.uploadProgress);
    updatedPaths.remove(type);
    updatedBytes.remove(type);
    updatedNames.remove(type);
    updatedUploads.remove(type);
    updatedProgress.remove(type);
    state = state.copyWith(
      documentPaths: updatedPaths,
      documentBytes: updatedBytes,
      documentFileNames: updatedNames,
      uploadedDocuments: updatedUploads,
      uploadProgress: updatedProgress,
    );
  }

  /// Sync registration form fields to the server while the doctor is onboarding.
  /// Document uploads only save files — this keeps name, specialty, clinic, etc.
  Future<void> saveRegistrationDraft() async {
    final doctor = _buildDoctorModel();
    if (doctor.firstName == null || doctor.firstName!.trim().isEmpty) {
      return;
    }

    try {
      await _repository.updateDoctorProfile(doctor: doctor);
    } catch (_) {
      // Best-effort while the doctor is still on the registration wizard.
    }
  }

  Future<bool> uploadDocument(DocumentType type) async {
    final bytes = state.documentBytes[type];
    final fileName = state.documentFileNames[type];
    final filePath = state.documentPaths[type];

    if (bytes == null && (filePath == null || filePath.isEmpty)) {
      state = state.copyWith(submitError: 'Please select a document to upload.');
      return false;
    }

    _setProgress(type, 0);

    try {
      final response = await _repository.uploadDocument(
        doctorId: state.draftId,
        bytes: bytes,
        filename: fileName,
        filePath: bytes == null ? filePath : null,
        documentType: type,
        onSendProgress: (sent, total) {
          if (total == 0) return;
          _setProgress(type, sent / total);
        },
      );

      if (response.success && response.data != null) {
        final updatedDocs = Map<DocumentType, DoctorDocumentModel>.from(
          state.uploadedDocuments,
        );
        updatedDocs[type] = response.data!;
        _setProgress(type, 1);
        state = state.copyWith(uploadedDocuments: updatedDocs, submitError: null);
        await saveRegistrationDraft();
        return true;
      }

      state = state.copyWith(
        submitError: response.error ?? 'Failed to upload document.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(submitError: 'An error occurred while uploading.');
      return false;
    }
  }

  Future<bool> submitRegistration() async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    var profileUrl = state.profileImagePath;
    final needsProfileUpload = state.profileImageBytes != null ||
        (profileUrl != null &&
            profileUrl.isNotEmpty &&
            !profileUrl.startsWith('http'));

    if (needsProfileUpload) {
      final upload = await _repository.uploadProfilePicture(
        doctorId: state.draftId,
        bytes: state.profileImageBytes,
        filename: state.profileImageFileName ?? 'profile.jpg',
        filePath: state.profileImageBytes == null ? profileUrl : null,
        mobileNumber: state.mobileNumber,
      );
      if (!upload.success) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: upload.error ?? 'Failed to upload profile picture.',
        );
        return false;
      }
      profileUrl = upload.data;
    }

    final doctor = _buildDoctorModel().copyWith(profilePicture: profileUrl);

    await saveRegistrationDraft();

    final notifier = _ref.read(doctorRegistrationProvider.notifier);
    final success = await notifier.submitRegistration(doctor);

    if (!success) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: notifier.state.error,
      );
      return false;
    }

    final doctorId = notifier.state.doctor?.id ?? state.draftId;

    if (state.offersOnlineConsult) {
      final availRes = await _repository.saveAvailability(
        doctorId: doctorId,
        selectedSlotKeys: state.selectedOnlineAvailabilitySlots,
        consultationType: 'online_consult',
      );
      if (!availRes.success) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: availRes.error ??
              'Registration saved but online consult availability failed to save.',
        );
        return false;
      }
    }

    if (state.offersVisitSite) {
      final availRes = await _repository.saveAvailability(
        doctorId: doctorId,
        selectedSlotKeys: state.selectedClinicAvailabilitySlots,
        consultationType: 'visit_site',
      );
      if (!availRes.success) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: availRes.error ??
              'Registration saved but clinic visit availability failed to save.',
        );
        return false;
      }
    }

    if (state.offersBookHome) {
      final availRes = await _repository.saveAvailability(
        doctorId: doctorId,
        selectedSlotKeys: state.selectedHomeAvailabilitySlots,
        consultationType: 'book_home',
      );
      if (!availRes.success) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: availRes.error ??
              'Registration saved but home visit availability failed to save.',
        );
        return false;
      }
    }

    state = state.copyWith(isSubmitting: false, submitError: null);
    return true;
  }

  DoctorModel _buildDoctorModel() {
    final sanitizedName = InputSanitizer.sanitizeText(state.fullName);
    final nameParts = sanitizedName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    final medicalLicense = state.uploadedDocuments[DocumentType.medicalLicense];
    final aadhaarCard = state.uploadedDocuments[DocumentType.aadhaarCard];
    final degree = state.uploadedDocuments[DocumentType.degreeCertificate];
    final clinicProof = state.uploadedDocuments[DocumentType.clinicProof];
    final cancelledCheque =
        state.uploadedDocuments[DocumentType.cancelledCheque];

    return DoctorModel(
      id: state.draftId,
      firstName: firstName,
      lastName: lastName,
      email: InputSanitizer.sanitizeEmail(state.email),
      mobileNumber: InputSanitizer.sanitizePhone(state.mobileNumber),
      countryCode: state.countryCode,
      password: state.password,
      profilePicture: state.profileImagePath,
      gender: state.gender,
      dateOfBirth: state.dateOfBirth,
      medicalRegistrationNumber:
          InputSanitizer.sanitizeText(state.medicalRegistrationNumber),
      medicalCouncilName: InputSanitizer.sanitizeText(state.medicalCouncilName),
      specializations: state.specializations,
      qualification: InputSanitizer.sanitizeText(state.qualification),
      yearsOfExperience: InputSanitizer.sanitizeInt(state.yearsOfExperience),
      clinicName: InputSanitizer.sanitizeText(state.clinicName),
      consultationFee: _minimumSelectedConsultationFee(),
      onlineConsultFee: state.offersOnlineConsult
          ? InputSanitizer.sanitizeInt(state.onlineConsultFee)
          : null,
      homeVisitFee: state.offersBookHome
          ? InputSanitizer.sanitizeInt(state.homeVisitFee)
          : null,
      visitSiteFee: state.offersVisitSite
          ? InputSanitizer.sanitizeInt(state.visitSiteFee)
          : null,
      languagesSpoken: state.languagesSpoken,
      bio: InputSanitizer.sanitizeMultiline(state.bio),
      address: InputSanitizer.sanitizeMultiline(state.address),
      city: InputSanitizer.sanitizeText(state.city),
      state: InputSanitizer.sanitizeText(state.state),
      pincode: InputSanitizer.sanitizeText(state.pincode),
      latitude: state.latitude,
      longitude: state.longitude,
      medicalLicenseUrl: medicalLicense?.fileUrl,
      aadhaarCardUrl: aadhaarCard?.fileUrl,
      degreeCertificateUrl: degree?.fileUrl,
      clinicProofUrl: clinicProof?.fileUrl,
      hospitalPhoto1Url: state.hospitalPhotoUrls[1],
      hospitalPhoto2Url: state.hospitalPhotoUrls[2],
      hospitalPhoto3Url: state.hospitalPhotoUrls[3],
      hospitalPhoto4Url: state.hospitalPhotoUrls[4],
      payoutMethod: state.payoutMethod,
      bankAccountNumber: InputSanitizer.sanitizeText(state.bankAccountNumber)
          .replaceAll(RegExp(r'\s'), ''),
      ifscCode: state.ifscCode.trim().toUpperCase(),
      cancelledChequeUrl: cancelledCheque?.fileUrl,
      upiId: state.upiId.trim().toLowerCase(),
      aadhaarLast4: state.aadhaarNumber.length >= 4
          ? state.aadhaarNumber.substring(state.aadhaarNumber.length - 4)
          : null,
      offersOnlineConsult: state.offersOnlineConsult,
      offersBookHome: state.offersBookHome,
      offersVisitSite: state.offersVisitSite,
    );
  }

  int? _minimumSelectedConsultationFee() {
    final fees = <int>[];
    if (state.offersOnlineConsult) {
      final fee = InputSanitizer.sanitizeInt(state.onlineConsultFee);
      if (fee != null) fees.add(fee);
    }
    if (state.offersBookHome) {
      final fee = InputSanitizer.sanitizeInt(state.homeVisitFee);
      if (fee != null) fees.add(fee);
    }
    if (state.offersVisitSite) {
      final fee = InputSanitizer.sanitizeInt(state.visitSiteFee);
      if (fee != null) fees.add(fee);
    }
    if (fees.isEmpty) return null;
    return fees.reduce((a, b) => a < b ? a : b);
  }

  void _setProgress(DocumentType type, double progress) {
    final updated = Map<DocumentType, double>.from(state.uploadProgress);
    updated[type] = progress;
    state = state.copyWith(uploadProgress: updated);
  }

  void _setHospitalPhotoProgress(int photoIndex, double progress) {
    final updated = Map<int, double>.from(state.hospitalPhotoUploadProgress);
    updated[photoIndex] = progress;
    state = state.copyWith(hospitalPhotoUploadProgress: updated);
  }
}

/// Provider for registration form notifier
final registrationFormProvider =
    StateNotifierProvider<RegistrationFormNotifier, RegistrationFormState>((ref) {
  final repository = ref.watch(doctorRegistrationRepositoryProvider);
  return RegistrationFormNotifier(ref, repository);
});

/// Provider for current registration step
final currentRegistrationStepProvider = StateProvider<int>((ref) {
  return 1;
});
