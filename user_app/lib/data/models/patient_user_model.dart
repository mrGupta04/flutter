import '../../core/constants/phone_countries.dart';
import '../../core/utils/validation_utils.dart';

class FamilyMemberModel {
  const FamilyMemberModel({
    required this.id,
    required this.name,
    this.relationship = 'other',
    this.age,
    this.gender,
    this.mobileNumber,
    this.bloodGroup,
  });

  final String id;
  final String name;
  final String relationship;
  final int? age;
  final String? gender;
  final String? mobileNumber;
  final String? bloodGroup;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'other',
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age']}'),
      gender: json['gender'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'relationship': relationship,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (mobileNumber != null) 'mobileNumber': mobileNumber,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
      };
}

class SavedAddressModel {
  const SavedAddressModel({
    required this.id,
    required this.addressLine,
    this.label = 'Home',
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String addressLine;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  String get displayLine {
    final parts = [
      addressLine,
      if (city != null && city!.isNotEmpty) city!,
      if (pincode != null && pincode!.isNotEmpty) pincode!,
    ];
    return parts.join(', ');
  }

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    return SavedAddressModel(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String? ?? 'Home',
      addressLine: json['addressLine'] as String? ?? '',
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'label': label,
        'addressLine': addressLine,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isDefault': isDefault,
      };
}

class MedicalProfileModel {
  const MedicalProfileModel({
    this.bloodGroup,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.currentMedications = const [],
    this.notes,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.insuranceMemberId,
    this.insuranceValidUntil,
  });

  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final List<String> currentMedications;
  final String? notes;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? insuranceMemberId;
  final String? insuranceValidUntil;

  factory MedicalProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MedicalProfileModel();
    return MedicalProfileModel(
      bloodGroup: json['bloodGroup'] as String?,
      allergies: (json['allergies'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      chronicDiseases: (json['chronicDiseases'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      currentMedications: (json['currentMedications'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      insuranceProvider: json['insuranceProvider'] as String?,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
      insuranceMemberId: json['insuranceMemberId'] as String?,
      insuranceValidUntil: json['insuranceValidUntil'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        'allergies': allergies,
        'chronicDiseases': chronicDiseases,
        'currentMedications': currentMedications,
        if (notes != null) 'notes': notes,
        if (insuranceProvider != null) 'insuranceProvider': insuranceProvider,
        if (insurancePolicyNumber != null)
          'insurancePolicyNumber': insurancePolicyNumber,
        if (insuranceMemberId != null) 'insuranceMemberId': insuranceMemberId,
        if (insuranceValidUntil != null)
          'insuranceValidUntil': insuranceValidUntil,
      };
}

class PatientUserModel {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final String mobileNumber;
  final String countryCode;
  final int? age;
  final String? gender;
  final String? aadhaarLast4;
  final String? profilePicture;
  final String? aadhaarCardUrl;
  final List<FamilyMemberModel> familyMembers;
  final List<SavedAddressModel> savedAddresses;
  final MedicalProfileModel medicalProfile;
  final String? referralCode;
  final int rewardPoints;
  final String? referredByCode;

  const PatientUserModel({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.mobileNumber,
    this.countryCode = PhoneCountries.defaultDialCode,
    this.age,
    this.gender,
    this.aadhaarLast4,
    this.profilePicture,
    this.aadhaarCardUrl,
    this.familyMembers = const [],
    this.savedAddresses = const [],
    this.medicalProfile = const MedicalProfileModel(),
    this.referralCode,
    this.rewardPoints = 0,
    this.referredByCode,
  });

  String get fullName {
    final last = lastName?.trim() ?? '';
    if (last.isEmpty) return firstName;
    return '$firstName $last'.trim();
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get aadhaarMaskedDisplay {
    if (aadhaarLast4 != null && aadhaarLast4!.length == 4) {
      return 'XXXX-XXXX-$aadhaarLast4';
    }
    return '—';
  }

  SavedAddressModel? get defaultAddress {
    if (savedAddresses.isEmpty) return null;
    for (final a in savedAddresses) {
      if (a.isDefault) return a;
    }
    return savedAddresses.first;
  }

  factory PatientUserModel.fromJson(Map<String, dynamic> json) {
    return PatientUserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      countryCode:
          json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age']}'),
      gender: json['gender'] as String?,
      aadhaarLast4: json['aadhaarLast4'] as String?,
      profilePicture: json['profilePicture'] as String?,
      aadhaarCardUrl: json['aadhaarCardUrl'] as String?,
      familyMembers: (json['familyMembers'] as List?)
              ?.whereType<Map>()
              .map((e) => FamilyMemberModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          const [],
      savedAddresses: (json['savedAddresses'] as List?)
              ?.whereType<Map>()
              .map((e) => SavedAddressModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          const [],
      medicalProfile: MedicalProfileModel.fromJson(
        json['medicalProfile'] as Map<String, dynamic>?,
      ),
      referralCode: json['referralCode'] as String?,
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      referredByCode: json['referredByCode'] as String?,
    );
  }

  String get formattedMobile => ValidationUtils.formatInternationalPhone(
        mobileNumber,
        countryCode: countryCode,
      );

  PatientUserModel copyWith({
    List<FamilyMemberModel>? familyMembers,
    List<SavedAddressModel>? savedAddresses,
    MedicalProfileModel? medicalProfile,
    String? referralCode,
    int? rewardPoints,
    String? referredByCode,
  }) {
    return PatientUserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobileNumber: mobileNumber,
      countryCode: countryCode,
      age: age,
      gender: gender,
      aadhaarLast4: aadhaarLast4,
      profilePicture: profilePicture,
      aadhaarCardUrl: aadhaarCardUrl,
      familyMembers: familyMembers ?? this.familyMembers,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      medicalProfile: medicalProfile ?? this.medicalProfile,
      referralCode: referralCode ?? this.referralCode,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      referredByCode: referredByCode ?? this.referredByCode,
    );
  }
}
