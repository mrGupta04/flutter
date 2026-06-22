import 'doctor_model.dart';

import '../../core/constants/phone_countries.dart';

class BloodBankModel {
  final String? id;
  final String? institutionName;
  final String? licenseNumber;
  final String? contactPerson;
  final String? email;
  final String? mobileNumber;
  final String? countryCode;
  final String? profilePicture;
  final String? emergencyContact;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final List<String>? bloodGroupsAvailable;
  final bool? hasApheresis;
  final bool? hasComponentSeparation;
  final bool? available24x7;
  final VerificationStatus? verificationStatus;

  BloodBankModel({
    this.id,
    this.institutionName,
    this.licenseNumber,
    this.contactPerson,
    this.email,
    this.mobileNumber,
    this.countryCode,
    this.profilePicture,
    this.emergencyContact,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.bloodGroupsAvailable,
    this.hasApheresis,
    this.hasComponentSeparation,
    this.available24x7,
    this.verificationStatus,
  });

  factory BloodBankModel.fromJson(Map<String, dynamic> json) {
    return BloodBankModel(
      id: json['id'] as String?,
      institutionName: json['institutionName'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      contactPerson: json['contactPerson'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      countryCode: json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      profilePicture: json['profilePicture'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bloodGroupsAvailable: (json['bloodGroupsAvailable'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      hasApheresis: json['hasApheresis'] as bool?,
      hasComponentSeparation: json['hasComponentSeparation'] as bool?,
      available24x7: json['available24x7'] as bool?,
      verificationStatus: _parseStatus(json['verificationStatus'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (institutionName != null) 'institutionName': institutionName,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (countryCode != null) 'countryCode': countryCode,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (bloodGroupsAvailable != null)
        'bloodGroupsAvailable': bloodGroupsAvailable,
      if (hasApheresis != null) 'hasApheresis': hasApheresis,
      if (hasComponentSeparation != null)
        'hasComponentSeparation': hasComponentSeparation,
      if (available24x7 != null) 'available24x7': available24x7,
    };
  }

  BloodBankModel copyWith({
    String? id,
    String? institutionName,
    String? licenseNumber,
    String? contactPerson,
    String? email,
    String? mobileNumber,
    String? profilePicture,
    String? emergencyContact,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    List<String>? bloodGroupsAvailable,
    bool? hasApheresis,
    bool? hasComponentSeparation,
    bool? available24x7,
    VerificationStatus? verificationStatus,
  }) {
    return BloodBankModel(
      id: id ?? this.id,
      institutionName: institutionName ?? this.institutionName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bloodGroupsAvailable: bloodGroupsAvailable ?? this.bloodGroupsAvailable,
      hasApheresis: hasApheresis ?? this.hasApheresis,
      hasComponentSeparation:
          hasComponentSeparation ?? this.hasComponentSeparation,
      available24x7: available24x7 ?? this.available24x7,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  static VerificationStatus? _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      default:
        return VerificationStatus.pending;
    }
  }
}
