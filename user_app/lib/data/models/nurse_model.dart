import 'doctor_model.dart';

import '../../core/constants/phone_countries.dart';
import '../../core/utils/doctor_presence_utils.dart';

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
  final VerificationStatus? verificationStatus;
  final double? averageRating;
  final int? ratingCount;
  final DateTime? lastActiveAt;
  final bool isLiveNow;

  bool get hasRating =>
      (ratingCount ?? 0) > 0 && averageRating != null && averageRating! > 0;

  /// Rating shown on listing cards (real average when available).
  double get cardDisplayRating => hasRating ? averageRating! : 4.5;

  /// Primary label for listing cards and profile hero (skills, then qualification).
  String get cardDesignationLabel {
    final skills = nursingSkills
            ?.where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList() ??
        const <String>[];
    if (skills.isNotEmpty) return skills.first;

    final qual = qualification?.trim();
    if (qual != null && qual.isNotEmpty) return qual;

    return 'Registered Nurse';
  }

  /// Secondary qualification line when it differs from [cardDesignationLabel].
  String? get cardQualificationSubtitle {
    final qual = qualification?.trim();
    if (qual == null || qual.isEmpty) return null;
    if (qual.toLowerCase() == cardDesignationLabel.toLowerCase()) return null;
    return qual;
  }

  /// Subtitle under the name on the profile hero.
  String? get profileHeroSubtitle {
    final designation = cardDesignationLabel;
    if (designation == 'Registered Nurse') return null;

    final qual = cardQualificationSubtitle;
    if (qual != null) return '$designation · $qual';
    return designation;
  }

  /// Payable home visit fee (offer when lower than regular).
  int? get effectiveHomeVisitFee {
    final regular = homeVisitFee;
    final offer = homeVisitOfferFee;
    if (offer != null && (regular == null || offer < regular)) return offer;
    return regular;
  }

  /// Regular fee shown struck-through when an offer is active.
  int? get originalHomeVisitFee {
    final regular = homeVisitFee;
    final offer = homeVisitOfferFee;
    if (offer != null && regular != null && offer < regular) return regular;
    return null;
  }

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
    this.verificationStatus,
    this.averageRating,
    this.ratingCount,
    this.lastActiveAt,
    this.isLiveNow = false,
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
      dateOfBirth: _parseDateTime(json['dateOfBirth']),
      languagesSpoken: _parseStringList(json['languagesSpoken']),
      qualification: json['qualification'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      nursingCouncil: json['nursingCouncil'] as String?,
      nuid: json['nuid'] as String?,
      yearsOfExperience: _parseInt(json['yearsOfExperience']),
      specialization: json['specialization'] as String?,
      nursingSkills: _parseStringList(json['nursingSkills']),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadiusKm: _parseInt(json['serviceRadiusKm']),
      availableForHomeVisit: json['availableForHomeVisit'] as bool? ?? true,
      homeVisitFee: _parseInt(json['homeVisitFee']),
      homeVisitOfferFee: _parseInt(json['homeVisitOfferFee']),
      shiftAvailability: json['shiftAvailability'] as String?,
      verificationStatus: _isApprovedTruthy(json['isApproved'])
          ? VerificationStatus.verified
          : _parseStatus(json['verificationStatus'] as String?),
      averageRating: _parseDouble(json['averageRating']),
      ratingCount: (json['ratingCount'] as num?)?.toInt(),
      lastActiveAt: _parseDateTime(json['lastActiveAt']),
      isLiveNow: _resolveIsLiveNow(
        json['isLiveNow'],
        _parseDateTime(json['lastActiveAt']),
      ),
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
      if (homeVisitFee != null) 'homeVisitFee': homeVisitFee,
      if (homeVisitOfferFee != null) 'homeVisitOfferFee': homeVisitOfferFee,
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
    DateTime? dateOfBirth,
    List<String>? languagesSpoken,
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
    VerificationStatus? verificationStatus,
    double? averageRating,
    int? ratingCount,
    DateTime? lastActiveAt,
    bool? isLiveNow,
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
      verificationStatus: verificationStatus ?? this.verificationStatus,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isLiveNow: isLiveNow ?? this.isLiveNow,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value == 1 || value == '1' || value == 'true') return true;
    if (value == 0 || value == '0' || value == 'false') return false;
    return null;
  }

  static bool _resolveIsLiveNow(dynamic rawLive, DateTime? lastActiveAt) {
    final parsed = _parseBool(rawLive);
    if (parsed != null) return parsed;
    return isDoctorLiveNow(lastActiveAt: lastActiveAt);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is! List) return null;
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
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

  static bool _isApprovedTruthy(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }
}
