import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/nurse_constants.dart';
import '../../../core/constants/phone_countries.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

final nurseRegistrationRepositoryProvider = Provider(
  (ref) => NurseRegistrationRepository(),
);

final currentNurseStepProvider = StateProvider<int>((ref) => 1);

class NurseRegistrationFormState {
  final String draftId;
  final String firstName;
  final String lastName;
  final String? gender;
  final DateTime? dateOfBirth;
  final List<String> languagesSpoken;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final String email;
  final String mobileNumber;
  final String countryCode;
  final String password;
  final String confirmPassword;
  final Uint8List? profileImageBytes;
  final String? profileImageFileName;
  final String? profilePictureUrl;
  final String qualification;
  final String qualificationOther;
  final String registrationNumber;
  final String nursingCouncil;
  final String nuid;
  final String yearsOfExperience;
  final String specialization;
  final List<String> nursingSkills;
  final String homeVisitFee;
  final String homeVisitOfferFee;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final int? serviceRadiusKm;
  final String bankAccountHolderName;
  final String bankAccountNumber;
  final String ifscCode;
  final String bankName;
  final Set<String> selectedHomeAvailabilitySlots;
  final Map<NurseDocumentType, String> documentUrls;
  final Map<NurseDocumentType, Uint8List> documentBytes;
  final Map<NurseDocumentType, String> documentFileNames;
  final bool isSubmitting;
  final String? submitError;

  NurseRegistrationFormState({
    required this.draftId,
    this.firstName = '',
    this.lastName = '',
    this.gender,
    this.dateOfBirth,
    this.languagesSpoken = const [],
    this.emergencyContactName = '',
    this.emergencyContactNumber = '',
    this.email = '',
    this.mobileNumber = '',
    this.countryCode = PhoneCountries.defaultDialCode,
    this.password = '',
    this.confirmPassword = '',
    this.profileImageBytes,
    this.profileImageFileName,
    this.profilePictureUrl,
    this.qualification = '',
    this.qualificationOther = '',
    this.registrationNumber = '',
    this.nursingCouncil = '',
    this.nuid = '',
    this.yearsOfExperience = '',
    this.specialization = '',
    this.nursingSkills = const [],
    this.homeVisitFee = '',
    this.homeVisitOfferFee = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.serviceRadiusKm,
    this.bankAccountHolderName = '',
    this.bankAccountNumber = '',
    this.ifscCode = '',
    this.bankName = '',
    this.selectedHomeAvailabilitySlots = const {},
    this.documentUrls = const {},
    this.documentBytes = const {},
    this.documentFileNames = const {},
    this.isSubmitting = false,
    this.submitError,
  });

  bool get hasProfileImage =>
      profileImageBytes != null || (profilePictureUrl?.isNotEmpty ?? false);

  String get resolvedQualification {
    if (qualification == 'Other') {
      return qualificationOther.trim();
    }
    return qualification.trim();
  }

  NurseRegistrationFormState copyWith({
    String? draftId,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    List<String>? languagesSpoken,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? email,
    String? mobileNumber,
    String? countryCode,
    String? password,
    String? confirmPassword,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
    String? profilePictureUrl,
    String? qualification,
    String? qualificationOther,
    String? registrationNumber,
    String? nursingCouncil,
    String? nuid,
    String? yearsOfExperience,
    String? specialization,
    List<String>? nursingSkills,
    String? homeVisitFee,
    String? homeVisitOfferFee,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    int? serviceRadiusKm,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
    Set<String>? selectedHomeAvailabilitySlots,
    Map<NurseDocumentType, String>? documentUrls,
    Map<NurseDocumentType, Uint8List>? documentBytes,
    Map<NurseDocumentType, String>? documentFileNames,
    bool? isSubmitting,
    String? submitError,
  }) {
    return NurseRegistrationFormState(
      draftId: draftId ?? this.draftId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber:
          emergencyContactNumber ?? this.emergencyContactNumber,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      countryCode: countryCode ?? this.countryCode,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      profileImageBytes: profileImageBytes ?? this.profileImageBytes,
      profileImageFileName: profileImageFileName ?? this.profileImageFileName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      qualification: qualification ?? this.qualification,
      qualificationOther: qualificationOther ?? this.qualificationOther,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      nursingCouncil: nursingCouncil ?? this.nursingCouncil,
      nuid: nuid ?? this.nuid,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      specialization: specialization ?? this.specialization,
      nursingSkills: nursingSkills ?? this.nursingSkills,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      homeVisitOfferFee: homeVisitOfferFee ?? this.homeVisitOfferFee,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      bankAccountHolderName:
          bankAccountHolderName ?? this.bankAccountHolderName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      selectedHomeAvailabilitySlots:
          selectedHomeAvailabilitySlots ?? this.selectedHomeAvailabilitySlots,
      documentUrls: documentUrls ?? this.documentUrls,
      documentBytes: documentBytes ?? this.documentBytes,
      documentFileNames: documentFileNames ?? this.documentFileNames,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
    );
  }

  NurseModel toNurseModel({String? profilePicture}) {
    return NurseModel(
      id: draftId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      gender: gender?.trim(),
      dateOfBirth: dateOfBirth,
      languagesSpoken: languagesSpoken,
      emergencyContactName: emergencyContactName.trim(),
      emergencyContactNumber: emergencyContactNumber.trim(),
      email: email.trim(),
      mobileNumber: mobileNumber.trim(),
      countryCode: countryCode,
      profilePicture: profilePicture,
      qualification: resolvedQualification,
      registrationNumber: registrationNumber.trim(),
      nursingCouncil: nursingCouncil.trim(),
      nuid: nuid.trim().isEmpty ? null : nuid.trim(),
      yearsOfExperience: int.tryParse(yearsOfExperience.trim()) ?? 0,
      specialization: specialization.trim(),
      nursingSkills: nursingSkills,
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      pincode: pincode.trim(),
      latitude: latitude,
      longitude: longitude,
      serviceRadiusKm: serviceRadiusKm,
      availableForHomeVisit: true,
      homeVisitFee: int.tryParse(homeVisitFee.trim()),
      homeVisitOfferFee: homeVisitOfferFee.trim().isEmpty
          ? null
          : int.tryParse(homeVisitOfferFee.trim()),
      bankAccountHolderName: bankAccountHolderName.trim(),
      bankAccountNumber: bankAccountNumber.trim(),
      ifscCode: ifscCode.trim(),
      bankName: bankName.trim(),
    );
  }
}

class NurseRegistrationFormNotifier
    extends StateNotifier<NurseRegistrationFormState> {
  NurseRegistrationFormNotifier(this._repository, this._ref)
      : super(NurseRegistrationFormState(draftId: const Uuid().v4()));

  final NurseRegistrationRepository _repository;
  final Ref _ref;

  void updatePersonal({
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    List<String>? languagesSpoken,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? email,
    String? mobileNumber,
    String? countryCode,
    String? password,
    String? confirmPassword,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
  }) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      dateOfBirth: dateOfBirth,
      languagesSpoken: languagesSpoken,
      emergencyContactName: emergencyContactName,
      emergencyContactNumber: emergencyContactNumber,
      email: email,
      mobileNumber: mobileNumber,
      countryCode: countryCode,
      password: password,
      confirmPassword: confirmPassword,
      profileImageBytes: profileImageBytes,
      profileImageFileName: profileImageFileName,
      submitError: null,
    );
  }

  void updateProfessional({
    String? qualification,
    String? qualificationOther,
    String? registrationNumber,
    String? nursingCouncil,
    String? nuid,
    String? yearsOfExperience,
    String? specialization,
    List<String>? nursingSkills,
    String? homeVisitFee,
    String? homeVisitOfferFee,
  }) {
    state = state.copyWith(
      qualification: qualification,
      qualificationOther: qualificationOther,
      registrationNumber: registrationNumber,
      nursingCouncil: nursingCouncil,
      nuid: nuid,
      yearsOfExperience: yearsOfExperience,
      specialization: specialization,
      nursingSkills: nursingSkills,
      homeVisitFee: homeVisitFee,
      homeVisitOfferFee: homeVisitOfferFee,
      submitError: null,
    );
  }

  void updateLocation({
    String? address,
    String? city,
    String? stateValue,
    String? pincode,
    double? latitude,
    double? longitude,
    int? serviceRadiusKm,
  }) {
    state = state.copyWith(
      address: address,
      city: city,
      state: stateValue,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      serviceRadiusKm: serviceRadiusKm,
      submitError: null,
    );
  }

  void updateBank({
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
  }) {
    state = state.copyWith(
      bankAccountHolderName: bankAccountHolderName,
      bankAccountNumber: bankAccountNumber,
      ifscCode: ifscCode,
      bankName: bankName,
      submitError: null,
    );
  }

  void toggleAvailabilitySlot(String key, bool selected) {
    final slots = Set<String>.from(state.selectedHomeAvailabilitySlots);
    if (selected) {
      slots.add(key);
    } else {
      slots.remove(key);
    }
    state = state.copyWith(
      selectedHomeAvailabilitySlots: slots,
      submitError: null,
    );
  }

  void setDocumentBytes(
    NurseDocumentType type,
    Uint8List bytes,
    String fileName,
  ) {
    final bytesMap = Map<NurseDocumentType, Uint8List>.from(state.documentBytes);
    final namesMap =
        Map<NurseDocumentType, String>.from(state.documentFileNames);
    bytesMap[type] = bytes;
    namesMap[type] = fileName;
    state = state.copyWith(
      documentBytes: bytesMap,
      documentFileNames: namesMap,
      submitError: null,
    );
  }

  void setDocumentUrl(NurseDocumentType type, String url) {
    final urls = Map<NurseDocumentType, String>.from(state.documentUrls);
    urls[type] = url;
    state = state.copyWith(documentUrls: urls, submitError: null);
  }

  Future<bool> uploadDocument(NurseDocumentType type) async {
    final bytes = state.documentBytes[type];
    final fileName = state.documentFileNames[type];
    if (bytes == null) {
      state = state.copyWith(submitError: 'Please select a document to upload.');
      return false;
    }

    final response = await _repository.uploadDocument(
      nurseId: state.draftId,
      documentType: type.apiValue,
      bytes: bytes,
      filename: fileName ?? '${type.apiValue}.jpg',
      mobileNumber: state.mobileNumber,
    );

    if (response.success && response.data != null) {
      final url = response.data!.fileUrl;
      if (url != null && url.isNotEmpty) {
        setDocumentUrl(type, url);
      }
      return true;
    }

    state = state.copyWith(
      submitError: response.error ?? 'Failed to upload document.',
    );
    return false;
  }

  Future<bool> submitRegistration() async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    var profileUrl = state.profilePictureUrl;
    if (state.profileImageBytes != null) {
      final upload = await _repository.uploadProfilePicture(
        nurseId: state.draftId,
        bytes: state.profileImageBytes!,
        filename: state.profileImageFileName ?? 'profile.jpg',
        mobileNumber: state.mobileNumber,
      );
      if (!upload.success || upload.data == null) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: upload.error ?? 'Failed to upload profile picture.',
        );
        return false;
      }
      profileUrl = upload.data;
    }

    for (final type in NurseDocumentType.values) {
      if (state.documentUrls.containsKey(type)) continue;
      if (state.documentBytes.containsKey(type)) {
        final ok = await uploadDocument(type);
        if (!ok) {
          state = state.copyWith(isSubmitting: false);
          return false;
        }
      }
    }

    final nurse = state.toNurseModel(profilePicture: profileUrl);
    final response = await _repository.register(
      nurse,
      password: state.password,
    );

    if (!response.success || response.data == null) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: response.error ?? 'Registration failed',
      );
      return false;
    }

    final nurseId = response.data!.id ?? state.draftId;
    final availRes = await _repository.saveAvailability(
      nurseId: nurseId,
      selectedSlotKeys: state.selectedHomeAvailabilitySlots,
    );

    if (!availRes.success) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: availRes.error ??
            'Registration saved but home visit availability failed to save.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: false, submitError: null);
    return true;
  }
}

final nurseRegistrationFormProvider = StateNotifierProvider<
    NurseRegistrationFormNotifier, NurseRegistrationFormState>((ref) {
  final repository = ref.watch(nurseRegistrationRepositoryProvider);
  return NurseRegistrationFormNotifier(repository, ref);
});

/// Legacy submit provider for profile refresh after registration.
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

  Future<void> refreshFromApi({String? nurseId}) async {
    final response = await repository.getProfile(nurseId: nurseId);
    if (response.success && response.data != null) {
      state = state.copyWith(nurse: response.data);
    }
  }

  void setNurse(NurseModel nurse) {
    state = state.copyWith(nurse: nurse);
  }
}

final nurseRegistrationProvider =
    StateNotifierProvider<NurseRegistrationNotifier, NurseRegistrationState>(
  (ref) {
    final repository = ref.watch(nurseRegistrationRepositoryProvider);
    return NurseRegistrationNotifier(repository);
  },
);
