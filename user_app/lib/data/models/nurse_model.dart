import 'doctor_model.dart';

import '../../core/constants/phone_countries.dart';

class NurseModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobileNumber;
  final String? countryCode;
  final String? profilePicture;
  final String? gender;
  final String? qualification;
  final String? registrationNumber;
  final String? nursingCouncil;
  final int? yearsOfExperience;
  final String? specialization;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final bool? availableForHomeVisit;
  final int? homeVisitFee;
  final String? shiftAvailability;
  final VerificationStatus? verificationStatus;

  NurseModel({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.mobileNumber,
    this.countryCode,
    this.profilePicture,
    this.gender,
    this.qualification,
    this.registrationNumber,
    this.nursingCouncil,
    this.yearsOfExperience,
    this.specialization,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.availableForHomeVisit,
    this.homeVisitFee,
    this.shiftAvailability,
    this.verificationStatus,
  });

  String get displayName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.join(' ').trim().isEmpty ? 'Nurse' : parts.join(' ');
  }

  factory NurseModel.fromJson(Map<String, dynamic> json) {
    return NurseModel(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      countryCode: json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      profilePicture: json['profilePicture'] as String?,
      gender: json['gender'] as String?,
      qualification: json['qualification'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      nursingCouncil: json['nursingCouncil'] as String?,
      yearsOfExperience: _parseInt(json['yearsOfExperience']),
      specialization: json['specialization'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      availableForHomeVisit: json['availableForHomeVisit'] as bool? ?? true,
      homeVisitFee: _parseInt(json['homeVisitFee']),
      shiftAvailability: json['shiftAvailability'] as String?,
      verificationStatus: _parseStatus(json['verificationStatus'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (countryCode != null) 'countryCode': countryCode,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (gender != null) 'gender': gender,
      if (qualification != null) 'qualification': qualification,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (nursingCouncil != null) 'nursingCouncil': nursingCouncil,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (specialization != null) 'specialization': specialization,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (availableForHomeVisit != null)
        'availableForHomeVisit': availableForHomeVisit,
      if (shiftAvailability != null) 'shiftAvailability': shiftAvailability,
    };
  }

  NurseModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    String? profilePicture,
    String? gender,
    String? qualification,
    String? registrationNumber,
    String? nursingCouncil,
    int? yearsOfExperience,
    String? specialization,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? availableForHomeVisit,
    String? shiftAvailability,
    VerificationStatus? verificationStatus,
  }) {
    return NurseModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      gender: gender ?? this.gender,
      qualification: qualification ?? this.qualification,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      nursingCouncil: nursingCouncil ?? this.nursingCouncil,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      specialization: specialization ?? this.specialization,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availableForHomeVisit:
          availableForHomeVisit ?? this.availableForHomeVisit,
      shiftAvailability: shiftAvailability ?? this.shiftAvailability,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
      default:
        return VerificationStatus.pending;
    }
  }
}
