import 'doctor_model.dart';

import '../../core/constants/phone_countries.dart';

/// Nurse profile and registration data.
class NurseModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobileNumber;
  final String? countryCode;
  final String? profilePicture;
  final String? gender;
  final DateTime? dateOfBirth;
  final List<String>? languagesSpoken;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? qualification;
  final String? registrationNumber;
  final String? nursingCouncil;
  final String? nuid;
  final int? yearsOfExperience;
  final String? specialization;
  final List<String>? nursingSkills;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final int? serviceRadiusKm;
  final bool? availableForHomeVisit;
  final int? homeVisitFee;
  final int? homeVisitOfferFee;
  final String? shiftAvailability;
  final String? bankAccountHolderName;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? bankName;
  final VerificationStatus? verificationStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isApproved;
  final String? approvalNotes;

  NurseModel({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.mobileNumber,
    this.countryCode,
    this.profilePicture,
    this.gender,
    this.dateOfBirth,
    this.languagesSpoken,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.qualification,
    this.registrationNumber,
    this.nursingCouncil,
    this.nuid,
    this.yearsOfExperience,
    this.specialization,
    this.nursingSkills,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm,
    this.availableForHomeVisit,
    this.homeVisitFee,
    this.homeVisitOfferFee,
    this.shiftAvailability,
    this.bankAccountHolderName,
    this.bankAccountNumber,
    this.ifscCode,
    this.bankName,
    this.verificationStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.isApproved,
    this.approvalNotes,
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
      countryCode:
          json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      profilePicture: json['profilePicture'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      languagesSpoken: _parseStringList(json['languagesSpoken']),
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactNumber: json['emergencyContactNumber'] as String?,
      qualification: json['qualification'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      nursingCouncil: json['nursingCouncil'] as String?,
      nuid: json['nuid'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      specialization: json['specialization'] as String?,
      nursingSkills: _parseStringList(json['nursingSkills']),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadiusKm: (json['serviceRadiusKm'] as num?)?.toInt(),
      availableForHomeVisit: json['availableForHomeVisit'] as bool? ?? true,
      homeVisitFee: (json['homeVisitFee'] as num?)?.toInt(),
      homeVisitOfferFee: (json['homeVisitOfferFee'] as num?)?.toInt(),
      shiftAvailability: json['shiftAvailability'] as String?,
      bankAccountHolderName: json['bankAccountHolderName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      bankName: json['bankName'] as String?,
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
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (countryCode != null) 'countryCode': countryCode,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (languagesSpoken != null) 'languagesSpoken': languagesSpoken,
      if (emergencyContactName != null)
        'emergencyContactName': emergencyContactName,
      if (emergencyContactNumber != null)
        'emergencyContactNumber': emergencyContactNumber,
      if (qualification != null) 'qualification': qualification,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (nursingCouncil != null) 'nursingCouncil': nursingCouncil,
      if (nuid != null) 'nuid': nuid,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (specialization != null) 'specialization': specialization,
      if (nursingSkills != null) 'nursingSkills': nursingSkills,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (serviceRadiusKm != null) 'serviceRadiusKm': serviceRadiusKm,
      if (availableForHomeVisit != null)
        'availableForHomeVisit': availableForHomeVisit,
      if (homeVisitFee != null) 'homeVisitFee': homeVisitFee,
      if (homeVisitOfferFee != null) 'homeVisitOfferFee': homeVisitOfferFee,
      if (shiftAvailability != null) 'shiftAvailability': shiftAvailability,
      if (bankAccountHolderName != null)
        'bankAccountHolderName': bankAccountHolderName,
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (ifscCode != null) 'ifscCode': ifscCode,
      if (bankName != null) 'bankName': bankName,
    };
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is! List) return null;
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
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

  NurseModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    String? profilePicture,
    String? gender,
    DateTime? dateOfBirth,
    List<String>? languagesSpoken,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? qualification,
    String? registrationNumber,
    String? nursingCouncil,
    String? nuid,
    int? yearsOfExperience,
    String? specialization,
    List<String>? nursingSkills,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    int? serviceRadiusKm,
    bool? availableForHomeVisit,
    int? homeVisitFee,
    int? homeVisitOfferFee,
    String? shiftAvailability,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    String? approvalNotes,
  }) {
    return NurseModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber:
          emergencyContactNumber ?? this.emergencyContactNumber,
      qualification: qualification ?? this.qualification,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      nursingCouncil: nursingCouncil ?? this.nursingCouncil,
      nuid: nuid ?? this.nuid,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      specialization: specialization ?? this.specialization,
      nursingSkills: nursingSkills ?? this.nursingSkills,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      availableForHomeVisit:
          availableForHomeVisit ?? this.availableForHomeVisit,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      homeVisitOfferFee: homeVisitOfferFee ?? this.homeVisitOfferFee,
      shiftAvailability: shiftAvailability ?? this.shiftAvailability,
      bankAccountHolderName:
          bankAccountHolderName ?? this.bankAccountHolderName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      approvalNotes: approvalNotes ?? this.approvalNotes,
    );
  }
}
