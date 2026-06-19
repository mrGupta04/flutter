class AmbulanceDriverModel {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String dateOfBirth;
  final String drivingLicenseNumber;
  final String drivingLicenseExpiry;
  final String emtCertificationNumber;
  final String emtCertificationExpiry;
  final String? assignedVehicleId;
  final String? governmentIdUrl;
  final String? drivingLicenseUrl;
  final String? emtCertificateUrl;
  final String? photoUrl;
  final bool backgroundCheckConsent;

  AmbulanceDriverModel({
    required this.id,
    this.fullName = '',
    this.mobileNumber = '',
    this.email = '',
    this.dateOfBirth = '',
    this.drivingLicenseNumber = '',
    this.drivingLicenseExpiry = '',
    this.emtCertificationNumber = '',
    this.emtCertificationExpiry = '',
    this.assignedVehicleId,
    this.governmentIdUrl,
    this.drivingLicenseUrl,
    this.emtCertificateUrl,
    this.photoUrl,
    this.backgroundCheckConsent = false,
  });

  factory AmbulanceDriverModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceDriverModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      drivingLicenseNumber: json['drivingLicenseNumber'] as String? ?? '',
      drivingLicenseExpiry: json['drivingLicenseExpiry'] as String? ?? '',
      emtCertificationNumber: json['emtCertificationNumber'] as String? ?? '',
      emtCertificationExpiry: json['emtCertificationExpiry'] as String? ?? '',
      assignedVehicleId: json['assignedVehicleId'] as String?,
      governmentIdUrl: json['governmentIdUrl'] as String?,
      drivingLicenseUrl: json['drivingLicenseUrl'] as String?,
      emtCertificateUrl: json['emtCertificateUrl'] as String?,
      photoUrl: json['photoUrl'] as String?,
      backgroundCheckConsent: json['backgroundCheckConsent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        'email': email,
        'dateOfBirth': dateOfBirth,
        'drivingLicenseNumber': drivingLicenseNumber,
        'drivingLicenseExpiry': drivingLicenseExpiry,
        'emtCertificationNumber': emtCertificationNumber,
        'emtCertificationExpiry': emtCertificationExpiry,
        if (assignedVehicleId != null) 'assignedVehicleId': assignedVehicleId,
        if (governmentIdUrl != null) 'governmentIdUrl': governmentIdUrl,
        if (drivingLicenseUrl != null) 'drivingLicenseUrl': drivingLicenseUrl,
        if (emtCertificateUrl != null) 'emtCertificateUrl': emtCertificateUrl,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'backgroundCheckConsent': backgroundCheckConsent,
      };

  AmbulanceDriverModel copyWith({
    String? id,
    String? fullName,
    String? mobileNumber,
    String? email,
    String? dateOfBirth,
    String? drivingLicenseNumber,
    String? drivingLicenseExpiry,
    String? emtCertificationNumber,
    String? emtCertificationExpiry,
    String? assignedVehicleId,
    String? governmentIdUrl,
    String? drivingLicenseUrl,
    String? emtCertificateUrl,
    String? photoUrl,
    bool? backgroundCheckConsent,
  }) {
    return AmbulanceDriverModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      drivingLicenseExpiry:
          drivingLicenseExpiry ?? this.drivingLicenseExpiry,
      emtCertificationNumber:
          emtCertificationNumber ?? this.emtCertificationNumber,
      emtCertificationExpiry:
          emtCertificationExpiry ?? this.emtCertificationExpiry,
      assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
      governmentIdUrl: governmentIdUrl ?? this.governmentIdUrl,
      drivingLicenseUrl: drivingLicenseUrl ?? this.drivingLicenseUrl,
      emtCertificateUrl: emtCertificateUrl ?? this.emtCertificateUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      backgroundCheckConsent:
          backgroundCheckConsent ?? this.backgroundCheckConsent,
    );
  }
}
