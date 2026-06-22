import 'ambulance_driver_model.dart';
import 'ambulance_vehicle_model.dart';
import 'doctor_model.dart';

import '../../core/constants/phone_countries.dart';

class AmbulanceModel {
  final String? id;
  final String? serviceName;
  final String? ownerName;
  final String? email;
  final String? mobileNumber;
  final String? countryCode;
  final String? profilePicture;
  final String? emergencyContact;
  final String? licenseNumber;
  final String? registrationNumber;
  final String? panNumber;
  final String? gstNumber;
  final String? companyRegistrationNumber;
  final int? vehicleCount;
  final List<String>? vehicleTypes;
  final List<AmbulanceVehicleModel>? vehicles;
  final List<AmbulanceDriverModel>? drivers;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? serviceArea;
  final bool? available24x7;
  final String? serviceLicenseUrl;
  final String? companyRegistrationUrl;
  final String? gstCertificateUrl;
  final String? fleetInsuranceUrl;
  final String? bankAccountHolderName;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? cancelledChequeUrl;
  final VerificationStatus? verificationStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isApproved;
  final String? approvalNotes;

  AmbulanceModel({
    this.id,
    this.serviceName,
    this.ownerName,
    this.email,
    this.mobileNumber,
    this.countryCode,
    this.profilePicture,
    this.emergencyContact,
    this.licenseNumber,
    this.registrationNumber,
    this.panNumber,
    this.gstNumber,
    this.companyRegistrationNumber,
    this.vehicleCount,
    this.vehicleTypes,
    this.vehicles,
    this.drivers,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.serviceArea,
    this.available24x7,
    this.serviceLicenseUrl,
    this.companyRegistrationUrl,
    this.gstCertificateUrl,
    this.fleetInsuranceUrl,
    this.bankAccountHolderName,
    this.bankAccountNumber,
    this.ifscCode,
    this.bankName,
    this.cancelledChequeUrl,
    this.verificationStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.isApproved,
    this.approvalNotes,
  });

  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceModel(
      id: json['id'] as String?,
      serviceName: json['serviceName'] as String?,
      ownerName: json['ownerName'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      countryCode: json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      profilePicture: json['profilePicture'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      gstNumber: json['gstNumber'] as String?,
      companyRegistrationNumber: json['companyRegistrationNumber'] as String?,
      vehicleCount: json['vehicleCount'] as int?,
      vehicleTypes: (json['vehicleTypes'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      vehicles: (json['vehicles'] as List?)
          ?.map((e) => AmbulanceVehicleModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList(),
      drivers: (json['drivers'] as List?)
          ?.map((e) => AmbulanceDriverModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceArea: json['serviceArea'] as String?,
      available24x7: json['available24x7'] as bool?,
      serviceLicenseUrl: json['serviceLicenseUrl'] as String?,
      companyRegistrationUrl: json['companyRegistrationUrl'] as String?,
      gstCertificateUrl: json['gstCertificateUrl'] as String?,
      fleetInsuranceUrl: json['fleetInsuranceUrl'] as String?,
      bankAccountHolderName: json['bankAccountHolderName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      bankName: json['bankName'] as String?,
      cancelledChequeUrl: json['cancelledChequeUrl'] as String?,
      verificationStatus: json['isApproved'] == true
          ? VerificationStatus.verified
          : _parseStatus(json['verificationStatus'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isApproved: json['isApproved'] as bool?,
      approvalNotes: json['approvalNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (serviceName != null) 'serviceName': serviceName,
      if (ownerName != null) 'ownerName': ownerName,
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (countryCode != null) 'countryCode': countryCode,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (panNumber != null) 'panNumber': panNumber,
      if (gstNumber != null) 'gstNumber': gstNumber,
      if (companyRegistrationNumber != null)
        'companyRegistrationNumber': companyRegistrationNumber,
      if (vehicleCount != null) 'vehicleCount': vehicleCount,
      if (vehicleTypes != null) 'vehicleTypes': vehicleTypes,
      if (vehicles != null) 'vehicles': vehicles!.map((v) => v.toJson()).toList(),
      if (drivers != null) 'drivers': drivers!.map((d) => d.toJson()).toList(),
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (serviceArea != null) 'serviceArea': serviceArea,
      if (available24x7 != null) 'available24x7': available24x7,
      if (serviceLicenseUrl != null) 'serviceLicenseUrl': serviceLicenseUrl,
      if (companyRegistrationUrl != null)
        'companyRegistrationUrl': companyRegistrationUrl,
      if (gstCertificateUrl != null) 'gstCertificateUrl': gstCertificateUrl,
      if (fleetInsuranceUrl != null) 'fleetInsuranceUrl': fleetInsuranceUrl,
      if (bankAccountHolderName != null)
        'bankAccountHolderName': bankAccountHolderName,
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (ifscCode != null) 'ifscCode': ifscCode,
      if (bankName != null) 'bankName': bankName,
      if (cancelledChequeUrl != null) 'cancelledChequeUrl': cancelledChequeUrl,
    };
  }

  static VerificationStatus? _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'under_review':
      case 'verifier_approved':
        return VerificationStatus.underReview;
      case 'pending':
      default:
        return VerificationStatus.pending;
    }
  }

  AmbulanceModel copyWith({
    String? id,
    String? serviceName,
    String? ownerName,
    String? email,
    String? mobileNumber,
    String? profilePicture,
    String? emergencyContact,
    String? licenseNumber,
    String? registrationNumber,
    String? panNumber,
    String? gstNumber,
    String? companyRegistrationNumber,
    int? vehicleCount,
    List<String>? vehicleTypes,
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
    String? serviceLicenseUrl,
    String? companyRegistrationUrl,
    String? gstCertificateUrl,
    String? fleetInsuranceUrl,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
    String? cancelledChequeUrl,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    String? approvalNotes,
  }) {
    return AmbulanceModel(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      panNumber: panNumber ?? this.panNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      companyRegistrationNumber:
          companyRegistrationNumber ?? this.companyRegistrationNumber,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
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
      serviceLicenseUrl: serviceLicenseUrl ?? this.serviceLicenseUrl,
      companyRegistrationUrl:
          companyRegistrationUrl ?? this.companyRegistrationUrl,
      gstCertificateUrl: gstCertificateUrl ?? this.gstCertificateUrl,
      fleetInsuranceUrl: fleetInsuranceUrl ?? this.fleetInsuranceUrl,
      bankAccountHolderName:
          bankAccountHolderName ?? this.bankAccountHolderName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      cancelledChequeUrl: cancelledChequeUrl ?? this.cancelledChequeUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      approvalNotes: approvalNotes ?? this.approvalNotes,
    );
  }
}
