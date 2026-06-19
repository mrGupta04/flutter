class PatientUserModel {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final String mobileNumber;
  final int? age;
  final String? gender;
  final String? aadhaarLast4;
  final String? profilePicture;
  final String? aadhaarCardUrl;

  const PatientUserModel({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.mobileNumber,
    this.age,
    this.gender,
    this.aadhaarLast4,
    this.profilePicture,
    this.aadhaarCardUrl,
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

  factory PatientUserModel.fromJson(Map<String, dynamic> json) {
    return PatientUserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age']}'),
      gender: json['gender'] as String?,
      aadhaarLast4: json['aadhaarLast4'] as String?,
      profilePicture: json['profilePicture'] as String?,
      aadhaarCardUrl: json['aadhaarCardUrl'] as String?,
    );
  }
}
