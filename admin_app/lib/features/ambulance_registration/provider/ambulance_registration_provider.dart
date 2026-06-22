import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/ambulance_constants.dart';
import '../../../core/constants/phone_countries.dart';
import '../../../data/models/ambulance_driver_model.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../data/models/ambulance_vehicle_model.dart';
import '../../../data/repositories/ambulance_registration_repository.dart';

final ambulanceRegistrationRepositoryProvider = Provider(
  (ref) => AmbulanceRegistrationRepository(),
);

final currentAmbulanceStepProvider = StateProvider<int>((ref) => 1);

class AmbulanceRegistrationFormState {
  final String draftId;
  final String serviceName;
  final String ownerName;
  final String email;
  final String mobileNumber;
  final String countryCode;
  final String password;
  final String confirmPassword;
  final String emergencyContact;
  final String licenseNumber;
  final String registrationNumber;
  final String panNumber;
  final String gstNumber;
  final String companyRegistrationNumber;
  final Uint8List? profileImageBytes;
  final String? profileImageFileName;
  final String? profilePictureUrl;
  final List<AmbulanceVehicleModel> vehicles;
  final List<AmbulanceDriverModel> drivers;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String serviceArea;
  final bool available24x7;
  final String bankAccountHolderName;
  final String bankAccountNumber;
  final String ifscCode;
  final String bankName;
  final Map<AmbulanceServiceDocumentType, String> serviceDocumentUrls;
  final Map<String, Map<AmbulanceVehicleDocumentType, String>> vehicleDocumentUrls;
  final Map<String, Map<AmbulanceDriverDocumentType, String>> driverDocumentUrls;
  final bool isSubmitting;
  final String? submitError;

  AmbulanceRegistrationFormState({
    required this.draftId,
    this.serviceName = '',
    this.ownerName = '',
    this.email = '',
    this.mobileNumber = '',
    this.countryCode = PhoneCountries.defaultDialCode,
    this.password = '',
    this.confirmPassword = '',
    this.emergencyContact = '',
    this.licenseNumber = '',
    this.registrationNumber = '',
    this.panNumber = '',
    this.gstNumber = '',
    this.companyRegistrationNumber = '',
    this.profileImageBytes,
    this.profileImageFileName,
    this.profilePictureUrl,
    this.vehicles = const [],
    this.drivers = const [],
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.serviceArea = '',
    this.available24x7 = false,
    this.bankAccountHolderName = '',
    this.bankAccountNumber = '',
    this.ifscCode = '',
    this.bankName = '',
    this.serviceDocumentUrls = const {},
    this.vehicleDocumentUrls = const {},
    this.driverDocumentUrls = const {},
    this.isSubmitting = false,
    this.submitError,
  });

  bool get hasProfileImage =>
      profileImageBytes != null || (profilePictureUrl?.isNotEmpty ?? false);

  AmbulanceRegistrationFormState copyWith({
    String? draftId,
    String? serviceName,
    String? ownerName,
    String? email,
    String? mobileNumber,
    String? countryCode,
    String? password,
    String? confirmPassword,
    String? emergencyContact,
    String? licenseNumber,
    String? registrationNumber,
    String? panNumber,
    String? gstNumber,
    String? companyRegistrationNumber,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
    String? profilePictureUrl,
    List<AmbulanceVehicleModel>? vehicles,
    List<AmbulanceDriverModel>? drivers,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? serviceArea,
    bool? available24x7,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
    Map<AmbulanceServiceDocumentType, String>? serviceDocumentUrls,
    Map<String, Map<AmbulanceVehicleDocumentType, String>>? vehicleDocumentUrls,
    Map<String, Map<AmbulanceDriverDocumentType, String>>? driverDocumentUrls,
    bool? isSubmitting,
    String? submitError,
  }) {
    return AmbulanceRegistrationFormState(
      draftId: draftId ?? this.draftId,
      serviceName: serviceName ?? this.serviceName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      countryCode: countryCode ?? this.countryCode,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      panNumber: panNumber ?? this.panNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      companyRegistrationNumber:
          companyRegistrationNumber ?? this.companyRegistrationNumber,
      profileImageBytes: profileImageBytes ?? this.profileImageBytes,
      profileImageFileName: profileImageFileName ?? this.profileImageFileName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      vehicles: vehicles ?? this.vehicles,
      drivers: drivers ?? this.drivers,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceArea: serviceArea ?? this.serviceArea,
      available24x7: available24x7 ?? this.available24x7,
      bankAccountHolderName:
          bankAccountHolderName ?? this.bankAccountHolderName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      serviceDocumentUrls: serviceDocumentUrls ?? this.serviceDocumentUrls,
      vehicleDocumentUrls: vehicleDocumentUrls ?? this.vehicleDocumentUrls,
      driverDocumentUrls: driverDocumentUrls ?? this.driverDocumentUrls,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
    );
  }

  AmbulanceModel toAmbulanceModel() {
    final vehicleTypes = vehicles.map((v) => v.vehicleType).where((t) => t.isNotEmpty).toSet().toList();
    return AmbulanceModel(
      id: draftId,
      serviceName: serviceName.trim(),
      ownerName: ownerName.trim(),
      email: email.trim(),
      mobileNumber: mobileNumber.trim(),
      countryCode: countryCode,
      profilePicture: profilePictureUrl,
      emergencyContact: emergencyContact.trim(),
      licenseNumber: licenseNumber.trim(),
      registrationNumber: registrationNumber.trim(),
      panNumber: panNumber.trim(),
      gstNumber: gstNumber.trim(),
      companyRegistrationNumber: companyRegistrationNumber.trim(),
      vehicleCount: vehicles.length,
      vehicleTypes: vehicleTypes,
      vehicles: vehicles,
      drivers: drivers,
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      pincode: pincode.trim(),
      latitude: latitude,
      longitude: longitude,
      serviceArea: serviceArea.trim(),
      available24x7: available24x7,
      serviceLicenseUrl: serviceDocumentUrls[AmbulanceServiceDocumentType.serviceLicense],
      companyRegistrationUrl: serviceDocumentUrls[AmbulanceServiceDocumentType.companyRegistration],
      gstCertificateUrl: serviceDocumentUrls[AmbulanceServiceDocumentType.gstCertificate],
      fleetInsuranceUrl: serviceDocumentUrls[AmbulanceServiceDocumentType.fleetInsurance],
      cancelledChequeUrl: serviceDocumentUrls[AmbulanceServiceDocumentType.cancelledCheque],
      bankAccountHolderName: bankAccountHolderName.trim(),
      bankAccountNumber: bankAccountNumber.trim(),
      ifscCode: ifscCode.trim(),
      bankName: bankName.trim(),
    );
  }
}

class AmbulanceRegistrationFormNotifier
    extends StateNotifier<AmbulanceRegistrationFormState> {
  AmbulanceRegistrationFormNotifier(this.repository)
      : super(AmbulanceRegistrationFormState(draftId: const Uuid().v4()));

  final AmbulanceRegistrationRepository repository;

  void updateServiceOwner({
    String? serviceName,
    String? ownerName,
    String? email,
    String? mobileNumber,
    String? countryCode,
    String? password,
    String? confirmPassword,
    String? emergencyContact,
    String? licenseNumber,
    String? registrationNumber,
    String? panNumber,
    String? gstNumber,
    String? companyRegistrationNumber,
  }) {
    state = state.copyWith(
      serviceName: serviceName,
      ownerName: ownerName,
      email: email,
      mobileNumber: mobileNumber,
      countryCode: countryCode,
      password: password,
      confirmPassword: confirmPassword,
      emergencyContact: emergencyContact,
      licenseNumber: licenseNumber,
      registrationNumber: registrationNumber,
      panNumber: panNumber,
      gstNumber: gstNumber,
      companyRegistrationNumber: companyRegistrationNumber,
    );
  }

  void setProfileImage({Uint8List? bytes, String? fileName}) {
    state = state.copyWith(
      profileImageBytes: bytes,
      profileImageFileName: fileName,
    );
  }

  void addVehicle(AmbulanceVehicleModel vehicle) {
    state = state.copyWith(vehicles: [...state.vehicles, vehicle]);
  }

  void updateVehicle(int index, AmbulanceVehicleModel vehicle) {
    final list = [...state.vehicles];
    if (index >= 0 && index < list.length) {
      list[index] = vehicle;
      state = state.copyWith(vehicles: list);
    }
  }

  void removeVehicle(int index) {
    final list = [...state.vehicles];
    if (index >= 0 && index < list.length) {
      final removedId = list[index].id;
      list.removeAt(index);
      final driverDocs = Map<String, Map<AmbulanceDriverDocumentType, String>>.from(state.driverDocumentUrls);
      final vehicleDocs = Map<String, Map<AmbulanceVehicleDocumentType, String>>.from(state.vehicleDocumentUrls);
      vehicleDocs.remove(removedId);
      final drivers = state.drivers
          .map((d) => d.assignedVehicleId == removedId
              ? d.copyWith(assignedVehicleId: null)
              : d)
          .toList();
      state = state.copyWith(
        vehicles: list,
        drivers: drivers,
        vehicleDocumentUrls: vehicleDocs,
        driverDocumentUrls: driverDocs,
      );
    }
  }

  void addDriver(AmbulanceDriverModel driver) {
    state = state.copyWith(drivers: [...state.drivers, driver]);
  }

  void updateDriver(int index, AmbulanceDriverModel driver) {
    final list = [...state.drivers];
    if (index >= 0 && index < list.length) {
      list[index] = driver;
      state = state.copyWith(drivers: list);
    }
  }

  void removeDriver(int index) {
    final list = [...state.drivers];
    if (index >= 0 && index < list.length) {
      final removedId = list[index].id;
      list.removeAt(index);
      final driverDocs = Map<String, Map<AmbulanceDriverDocumentType, String>>.from(state.driverDocumentUrls);
      driverDocs.remove(removedId);
      state = state.copyWith(drivers: list, driverDocumentUrls: driverDocs);
    }
  }

  void updateLocation({
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? serviceArea,
    bool? available24x7,
  }) {
    this.state = this.state.copyWith(
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      serviceArea: serviceArea,
      available24x7: available24x7,
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
    );
  }

  void setServiceDocumentUrl(AmbulanceServiceDocumentType type, String url) {
    final docs = Map<AmbulanceServiceDocumentType, String>.from(state.serviceDocumentUrls);
    docs[type] = url;
    state = state.copyWith(serviceDocumentUrls: docs);
  }

  void setVehicleDocumentUrl(
    String vehicleId,
    AmbulanceVehicleDocumentType type,
    String url,
  ) {
    final docs = Map<String, Map<AmbulanceVehicleDocumentType, String>>.from(
      state.vehicleDocumentUrls,
    );
    docs.putIfAbsent(vehicleId, () => {});
    docs[vehicleId]![type] = url;
    state = state.copyWith(vehicleDocumentUrls: docs);
  }

  void setDriverDocumentUrl(
    String driverId,
    AmbulanceDriverDocumentType type,
    String url,
  ) {
    final docs = Map<String, Map<AmbulanceDriverDocumentType, String>>.from(
      state.driverDocumentUrls,
    );
    docs.putIfAbsent(driverId, () => {});
    docs[driverId]![type] = url;
    state = state.copyWith(driverDocumentUrls: docs);
  }

  Future<String?> uploadServiceDocument({
    required AmbulanceServiceDocumentType type,
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await repository.uploadDocument(
      ambulanceId: state.draftId,
      documentType: type.apiValue,
      bytes: bytes,
      filename: filename,
      mobileNumber: state.mobileNumber,
    );
    if (response.success && response.data != null) {
      setServiceDocumentUrl(type, response.data!);
      return response.data;
    }
    return null;
  }

  Future<String?> uploadVehicleDocument({
    required String vehicleId,
    required AmbulanceVehicleDocumentType type,
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await repository.uploadDocument(
      ambulanceId: state.draftId,
      documentType: type.apiValue,
      vehicleId: vehicleId,
      bytes: bytes,
      filename: filename,
      mobileNumber: state.mobileNumber,
    );
    if (response.success && response.data != null) {
      setVehicleDocumentUrl(vehicleId, type, response.data!);
      return response.data;
    }
    return null;
  }

  Future<String?> uploadDriverDocument({
    required String driverId,
    required AmbulanceDriverDocumentType type,
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await repository.uploadDocument(
      ambulanceId: state.draftId,
      documentType: type.apiValue,
      driverId: driverId,
      bytes: bytes,
      filename: filename,
      mobileNumber: state.mobileNumber,
    );
    if (response.success && response.data != null) {
      setDriverDocumentUrl(driverId, type, response.data!);
      return response.data;
    }
    return null;
  }

  Future<bool> submitRegistration() async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    var model = state.toAmbulanceModel();

    if (state.profileImageBytes != null) {
      final upload = await repository.uploadProfilePicture(
        ambulanceId: state.draftId,
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
      model = model.copyWith(profilePicture: upload.data);
      state = state.copyWith(profilePictureUrl: upload.data);
    }

    final vehiclesWithDocs = state.vehicles.map((v) {
      final docs = state.vehicleDocumentUrls[v.id] ?? {};
      return v.copyWith(
        rcBookUrl: docs[AmbulanceVehicleDocumentType.rcBook],
        insuranceUrl: docs[AmbulanceVehicleDocumentType.insurance],
        fitnessCertificateUrl: docs[AmbulanceVehicleDocumentType.fitnessCertificate],
        pollutionCertificateUrl: docs[AmbulanceVehicleDocumentType.pollutionCertificate],
        photoFrontUrl: docs[AmbulanceVehicleDocumentType.photoFront],
        photoBackUrl: docs[AmbulanceVehicleDocumentType.photoBack],
        photoInteriorUrl: docs[AmbulanceVehicleDocumentType.photoInterior],
      );
    }).toList();

    final driversWithDocs = state.drivers.map((d) {
      final docs = state.driverDocumentUrls[d.id] ?? {};
      return d.copyWith(
        governmentIdUrl: docs[AmbulanceDriverDocumentType.governmentId],
        drivingLicenseUrl: docs[AmbulanceDriverDocumentType.drivingLicense],
        emtCertificateUrl: docs[AmbulanceDriverDocumentType.emtCertificate],
        photoUrl: docs[AmbulanceDriverDocumentType.photo],
      );
    }).toList();

    model = model.copyWith(vehicles: vehiclesWithDocs, drivers: driversWithDocs);

    final response = await repository.register(
      model,
      password: state.password.isNotEmpty ? state.password : null,
    );

    if (response.success) {
      state = state.copyWith(isSubmitting: false);
      return true;
    }

    state = state.copyWith(
      isSubmitting: false,
      submitError: response.error ?? 'Registration failed',
    );
    return false;
  }
}

final ambulanceRegistrationFormProvider = StateNotifierProvider<
    AmbulanceRegistrationFormNotifier, AmbulanceRegistrationFormState>((ref) {
  return AmbulanceRegistrationFormNotifier(
    ref.watch(ambulanceRegistrationRepositoryProvider),
  );
});

/// Legacy provider used by provider profile sync.
class AmbulanceRegistrationState {
  final AmbulanceModel? ambulance;
  AmbulanceRegistrationState({this.ambulance});
}

class AmbulanceRegistrationNotifier extends StateNotifier<AmbulanceRegistrationState> {
  AmbulanceRegistrationNotifier() : super(AmbulanceRegistrationState());

  void setAmbulance(AmbulanceModel ambulance) {
    state = AmbulanceRegistrationState(ambulance: ambulance);
  }
}

final ambulanceRegistrationProvider = StateNotifierProvider<
    AmbulanceRegistrationNotifier, AmbulanceRegistrationState>((ref) {
  return AmbulanceRegistrationNotifier();
});
