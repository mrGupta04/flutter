class ReceptionistModel {
  const ReceptionistModel({
    required this.id,
    required this.doctorId,
    required this.name,
    required this.email,
    this.phone,
    this.clinicId,
    this.status = 'active',
    this.lastLoginAt,
    this.createdAt,
  });

  final String id;
  final String doctorId;
  final String? clinicId;
  final String name;
  final String email;
  final String? phone;
  final String status;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory ReceptionistModel.fromJson(Map<String, dynamic> json) {
    return ReceptionistModel(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      clinicId: json['clinicId']?.toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      lastLoginAt: _parseDate(json['lastLoginAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class ClinicVisitModel {
  const ClinicVisitModel({
    required this.id,
    required this.patientName,
    this.patientProfilePicture,
    this.patientMobile,
    this.visitReason,
    this.slotStart,
    this.slotEnd,
    this.label,
    this.status = 'confirmed',
    this.visitProgress,
    this.displayStatus = 'PENDING_VERIFICATION',
    this.verificationStatus,
    this.verifiedByName,
    this.verifiedAt,
    this.patientArrivedAt,
    this.canVerify = false,
  });

  final String id;
  final String patientName;
  final String? patientProfilePicture;
  final String? patientMobile;
  final String? visitReason;
  final DateTime? slotStart;
  final DateTime? slotEnd;
  final String? label;
  final String status;
  final String? visitProgress;
  final String displayStatus;
  final String? verificationStatus;
  final String? verifiedByName;
  final DateTime? verifiedAt;
  final DateTime? patientArrivedAt;
  final bool canVerify;

  bool get isVerified =>
      verificationStatus == 'VERIFIED' ||
      displayStatus == 'VERIFIED' ||
      displayStatus == 'CONSULTATION_STARTED' ||
      displayStatus == 'COMPLETED' ||
      patientArrivedAt != null;

  bool get isCancelled =>
      status == 'cancelled' || displayStatus == 'CANCELLED';

  factory ClinicVisitModel.fromJson(Map<String, dynamic> json) {
    return ClinicVisitModel(
      id: json['id']?.toString() ?? json['bookingId']?.toString() ?? '',
      patientName: json['patientName'] as String? ?? 'Patient',
      patientProfilePicture: json['patientProfilePicture'] as String?,
      patientMobile: json['patientMobile'] as String?,
      visitReason: json['visitReason'] as String?,
      slotStart: _parseDate(json['slotStart']),
      slotEnd: _parseDate(json['slotEnd']),
      label: json['label'] as String?,
      status: json['status'] as String? ?? 'confirmed',
      visitProgress: json['visitProgress'] as String?,
      displayStatus: json['displayStatus'] as String? ?? 'PENDING_VERIFICATION',
      verificationStatus: json['verificationStatus'] as String?,
      verifiedByName: json['verifiedByName'] as String?,
      verifiedAt: _parseDate(json['verifiedAt'] ?? json['appointmentVerifiedAt']),
      patientArrivedAt: _parseDate(json['patientArrivedAt']),
      canVerify: json['canVerify'] as bool? ?? false,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
