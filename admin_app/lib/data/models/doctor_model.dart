import 'consultation_type.dart';

/// Enumeration for verification status
enum VerificationStatus {
  pending,
  verified,
  rejected,
  underReview,
}

/// How consultation payouts are received.
enum PayoutMethod {
  bank,
  upi;

  String get apiValue => name;

  String get label => switch (this) {
        PayoutMethod.bank => 'Bank account',
        PayoutMethod.upi => 'UPI',
      };

  static PayoutMethod fromApi(String? value) {
    if (value == 'upi') return PayoutMethod.upi;
    return PayoutMethod.bank;
  }
}

/// Doctor model representing a doctor's profile and registration data
class DoctorModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobileNumber;
  final String? password;
  final String? profilePicture;
  final String? gender;
  final DateTime? dateOfBirth;

  // Professional Details
  final String? medicalRegistrationNumber;
  final String? medicalCouncilName;
  final List<String>? specializations;
  final String? qualification;
  final int? yearsOfExperience;
  final String? clinicName;
  final int? consultationFee;
  final int? onlineConsultFee;
  final int? homeVisitFee;
  final int? visitSiteFee;
  final bool offersOnlineConsult;
  final bool offersBookHome;
  final bool offersVisitSite;
  final List<String>? languagesSpoken;
  final String? bio;

  // Address Details
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;

  // Documents
  final String? medicalLicenseUrl;
  final String? governmentIdUrl;
  final String? degreeCertificateUrl;
  final String? clinicProofUrl;
  final String? hospitalPhoto1Url;
  final String? hospitalPhoto2Url;
  final String? hospitalPhoto3Url;
  final String? hospitalPhoto4Url;
  final String? hospitalPhoto5Url;

  // Aadhaar
  final String? aadhaarLast4;
  final String? aadhaarCardUrl;
  final bool? aadhaarVerified;
  final DateTime? aadhaarVerifiedAt;
  final bool? emailVerified;
  final DateTime? emailVerifiedAt;
  final bool? phoneVerified;
  final DateTime? phoneVerifiedAt;

  // Bank / payout
  final PayoutMethod payoutMethod;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? cancelledChequeUrl;
  final String? upiId;

  // Status
  final VerificationStatus? verificationStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isApproved;
  final String? approvalNotes;

  DoctorModel({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.mobileNumber,
    this.password,
    this.profilePicture,
    this.gender,
    this.dateOfBirth,
    this.medicalRegistrationNumber,
    this.medicalCouncilName,
    this.specializations,
    this.qualification,
    this.yearsOfExperience,
    this.clinicName,
    this.consultationFee,
    this.onlineConsultFee,
    this.homeVisitFee,
    this.visitSiteFee,
    this.offersOnlineConsult = false,
    this.offersBookHome = false,
    this.offersVisitSite = false,
    this.languagesSpoken,
    this.bio,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.medicalLicenseUrl,
    this.governmentIdUrl,
    this.degreeCertificateUrl,
    this.clinicProofUrl,
    this.hospitalPhoto1Url,
    this.hospitalPhoto2Url,
    this.hospitalPhoto3Url,
    this.hospitalPhoto4Url,
    this.hospitalPhoto5Url,
    this.aadhaarLast4,
    this.aadhaarCardUrl,
    this.aadhaarVerified,
    this.aadhaarVerifiedAt,
    this.emailVerified,
    this.emailVerifiedAt,
    this.phoneVerified,
    this.phoneVerifiedAt,
    this.payoutMethod = PayoutMethod.bank,
    this.bankAccountNumber,
    this.ifscCode,
    this.cancelledChequeUrl,
    this.upiId,
    this.verificationStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.isApproved,
    this.approvalNotes,
  });

  /// Get full name
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  bool offersConsultationType(ConsultationType type) {
    switch (type) {
      case ConsultationType.onlineConsult:
        return offersOnlineConsult;
      case ConsultationType.bookHome:
        return offersBookHome;
      case ConsultationType.visitSite:
        return offersVisitSite;
    }
  }

  List<ConsultationType> get availableConsultationTypes {
    return ConsultationType.values
        .where(offersConsultationType)
        .toList(growable: false);
  }

  bool get hasAnyConsultationOption =>
      offersOnlineConsult || offersBookHome || offersVisitSite;

  int? feeForConsultationType(ConsultationType type) {
    switch (type) {
      case ConsultationType.onlineConsult:
        return onlineConsultFee ?? consultationFee;
      case ConsultationType.bookHome:
        return homeVisitFee ?? consultationFee;
      case ConsultationType.visitSite:
        return visitSiteFee ?? consultationFee;
    }
  }

  int? get lowestConsultationFee {
    final fees = availableConsultationTypes
        .map(feeForConsultationType)
        .whereType<int>()
        .where((fee) => fee > 0)
        .toList();
    if (fees.isEmpty) return consultationFee;
    return fees.reduce((a, b) => a < b ? a : b);
  }

  /// Get age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Check if all required fields are filled
  bool get isProfileComplete {
    return firstName != null &&
        lastName != null &&
        email != null &&
        mobileNumber != null &&
        medicalRegistrationNumber != null &&
        medicalCouncilName != null &&
        specializations != null &&
        specializations!.isNotEmpty &&
        qualification != null &&
        yearsOfExperience != null &&
        clinicName != null &&
        consultationFee != null &&
        address != null &&
        city != null &&
        state != null &&
        pincode != null;
  }

  /// Get verification badge color
  String get verificationBadgeColor {
    switch (verificationStatus) {
      case VerificationStatus.verified:
        return '#26D07C';
      case VerificationStatus.rejected:
        return '#E63946';
      case VerificationStatus.underReview:
      case VerificationStatus.pending:
      default:
        return '#FFA500';
    }
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      password: json['password'] as String?,
      profilePicture: json['profilePicture'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: _parseDateTime(json['dateOfBirth']),
      medicalRegistrationNumber: json['medicalRegistrationNumber'] as String?,
      medicalCouncilName: json['medicalCouncilName'] as String?,
      specializations: _parseStringList(json['specializations']),
      qualification: json['qualification'] as String?,
      yearsOfExperience: _parseInt(json['yearsOfExperience']),
      clinicName: json['clinicName'] as String?,
      consultationFee: _parseInt(json['consultationFee']),
      onlineConsultFee: _parseInt(json['onlineConsultFee']),
      homeVisitFee: _parseInt(json['homeVisitFee']),
      visitSiteFee: _parseInt(json['visitSiteFee']),
      offersOnlineConsult: json['offersOnlineConsult'] as bool? ?? false,
      offersBookHome: json['offersBookHome'] as bool? ?? false,
      offersVisitSite: json['offersVisitSite'] as bool? ?? false,
      languagesSpoken: _parseStringList(json['languagesSpoken']),
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      medicalLicenseUrl: json['medicalLicenseUrl'] as String?,
      governmentIdUrl: json['governmentIdUrl'] as String?,
      degreeCertificateUrl: json['degreeCertificateUrl'] as String?,
      clinicProofUrl: json['clinicProofUrl'] as String?,
      hospitalPhoto1Url: json['hospitalPhoto1Url'] as String?,
      hospitalPhoto2Url: json['hospitalPhoto2Url'] as String?,
      hospitalPhoto3Url: json['hospitalPhoto3Url'] as String?,
      hospitalPhoto4Url: json['hospitalPhoto4Url'] as String?,
      hospitalPhoto5Url: json['hospitalPhoto5Url'] as String?,
      aadhaarLast4: json['aadhaarLast4'] as String?,
      aadhaarCardUrl: json['aadhaarCardUrl'] as String?,
      aadhaarVerified: json['aadhaarVerified'] as bool?,
      aadhaarVerifiedAt: _parseDateTime(json['aadhaarVerifiedAt']),
      emailVerified: json['emailVerified'] as bool?,
      emailVerifiedAt: _parseDateTime(json['emailVerifiedAt']),
      phoneVerified: json['phoneVerified'] as bool?,
      phoneVerifiedAt: _parseDateTime(json['phoneVerifiedAt']),
      payoutMethod: PayoutMethod.fromApi(json['payoutMethod'] as String?),
      bankAccountNumber: json['bankAccountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      cancelledChequeUrl: json['cancelledChequeUrl'] as String?,
      upiId: json['upiId'] as String?,
      verificationStatus: _isApprovedTruthy(json['isApproved'])
          ? VerificationStatus.verified
          : _parseVerificationStatus(json['verificationStatus'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isApproved: json['isApproved'] as bool?,
      approvalNotes: json['approvalNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'password': password,
      'profilePicture': profilePicture,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'medicalRegistrationNumber': medicalRegistrationNumber,
      'medicalCouncilName': medicalCouncilName,
      'specializations': specializations,
      'qualification': qualification,
      'yearsOfExperience': yearsOfExperience,
      'clinicName': clinicName,
      'consultationFee': consultationFee,
      'onlineConsultFee': onlineConsultFee,
      'homeVisitFee': homeVisitFee,
      'visitSiteFee': visitSiteFee,
      'offersOnlineConsult': offersOnlineConsult,
      'offersBookHome': offersBookHome,
      'offersVisitSite': offersVisitSite,
      'languagesSpoken': languagesSpoken,
      'bio': bio,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'medicalLicenseUrl': medicalLicenseUrl,
      'governmentIdUrl': governmentIdUrl,
      'degreeCertificateUrl': degreeCertificateUrl,
      'clinicProofUrl': clinicProofUrl,
      'hospitalPhoto1Url': hospitalPhoto1Url,
      'hospitalPhoto2Url': hospitalPhoto2Url,
      'hospitalPhoto3Url': hospitalPhoto3Url,
      'hospitalPhoto4Url': hospitalPhoto4Url,
      'hospitalPhoto5Url': hospitalPhoto5Url,
      'aadhaarLast4': aadhaarLast4,
      'aadhaarCardUrl': aadhaarCardUrl,
      'aadhaarVerified': aadhaarVerified,
      'aadhaarVerifiedAt': aadhaarVerifiedAt?.toIso8601String(),
      'emailVerified': emailVerified,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'phoneVerified': phoneVerified,
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'payoutMethod': payoutMethod.apiValue,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'cancelledChequeUrl': cancelledChequeUrl,
      'upiId': upiId,
      'verificationStatus': _verificationStatusToJson(verificationStatus),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isApproved': isApproved,
      'approvalNotes': approvalNotes,
    };
  }

  /// Create a copy of the model with updated fields
  DoctorModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    String? password,
    String? profilePicture,
    String? gender,
    DateTime? dateOfBirth,
    String? medicalRegistrationNumber,
    String? medicalCouncilName,
    List<String>? specializations,
    String? qualification,
    int? yearsOfExperience,
    String? clinicName,
    int? consultationFee,
    int? onlineConsultFee,
    int? homeVisitFee,
    int? visitSiteFee,
    bool? offersOnlineConsult,
    bool? offersBookHome,
    bool? offersVisitSite,
    List<String>? languagesSpoken,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? medicalLicenseUrl,
    String? governmentIdUrl,
    String? degreeCertificateUrl,
    String? clinicProofUrl,
    String? hospitalPhoto1Url,
    String? hospitalPhoto2Url,
    String? hospitalPhoto3Url,
    String? hospitalPhoto4Url,
    String? hospitalPhoto5Url,
    String? aadhaarLast4,
    String? aadhaarCardUrl,
    bool? aadhaarVerified,
    DateTime? aadhaarVerifiedAt,
    bool? emailVerified,
    DateTime? emailVerifiedAt,
    bool? phoneVerified,
    DateTime? phoneVerifiedAt,
    PayoutMethod? payoutMethod,
    String? bankAccountNumber,
    String? ifscCode,
    String? cancelledChequeUrl,
    String? upiId,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    String? approvalNotes,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      password: password ?? this.password,
      profilePicture: profilePicture ?? this.profilePicture,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      medicalRegistrationNumber: medicalRegistrationNumber ?? this.medicalRegistrationNumber,
      medicalCouncilName: medicalCouncilName ?? this.medicalCouncilName,
      specializations: specializations ?? this.specializations,
      qualification: qualification ?? this.qualification,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      clinicName: clinicName ?? this.clinicName,
      consultationFee: consultationFee ?? this.consultationFee,
      onlineConsultFee: onlineConsultFee ?? this.onlineConsultFee,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      visitSiteFee: visitSiteFee ?? this.visitSiteFee,
      offersOnlineConsult: offersOnlineConsult ?? this.offersOnlineConsult,
      offersBookHome: offersBookHome ?? this.offersBookHome,
      offersVisitSite: offersVisitSite ?? this.offersVisitSite,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      medicalLicenseUrl: medicalLicenseUrl ?? this.medicalLicenseUrl,
      governmentIdUrl: governmentIdUrl ?? this.governmentIdUrl,
      degreeCertificateUrl: degreeCertificateUrl ?? this.degreeCertificateUrl,
      clinicProofUrl: clinicProofUrl ?? this.clinicProofUrl,
      hospitalPhoto1Url: hospitalPhoto1Url ?? this.hospitalPhoto1Url,
      hospitalPhoto2Url: hospitalPhoto2Url ?? this.hospitalPhoto2Url,
      hospitalPhoto3Url: hospitalPhoto3Url ?? this.hospitalPhoto3Url,
      hospitalPhoto4Url: hospitalPhoto4Url ?? this.hospitalPhoto4Url,
      hospitalPhoto5Url: hospitalPhoto5Url ?? this.hospitalPhoto5Url,
      aadhaarLast4: aadhaarLast4 ?? this.aadhaarLast4,
      aadhaarCardUrl: aadhaarCardUrl ?? this.aadhaarCardUrl,
      aadhaarVerified: aadhaarVerified ?? this.aadhaarVerified,
      aadhaarVerifiedAt: aadhaarVerifiedAt ?? this.aadhaarVerifiedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      cancelledChequeUrl: cancelledChequeUrl ?? this.cancelledChequeUrl,
      upiId: upiId ?? this.upiId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      approvalNotes: approvalNotes ?? this.approvalNotes,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

List<String>? _parseStringList(dynamic value) {
  if (value is! List) return null;
  return value.map((e) => e.toString()).toList();
}

bool _isApprovedTruthy(dynamic value) {
  if (value == true || value == 1) return true;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}

VerificationStatus? _parseVerificationStatus(String? value) {
  switch (value) {
    case 'pending':
      return VerificationStatus.pending;
    case 'verified':
      return VerificationStatus.verified;
    case 'rejected':
      return VerificationStatus.rejected;
    case 'under_review':
    case 'verifier_approved':
      return VerificationStatus.underReview;
    default:
      return null;
  }
}

String? _verificationStatusToJson(VerificationStatus? status) {
  switch (status) {
    case VerificationStatus.pending:
      return 'pending';
    case VerificationStatus.verified:
      return 'verified';
    case VerificationStatus.rejected:
      return 'rejected';
    case VerificationStatus.underReview:
      return 'under_review';
    default:
      return null;
  }
}
