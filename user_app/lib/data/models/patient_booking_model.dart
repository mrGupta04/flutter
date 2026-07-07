import 'bookable_slot_model.dart';
import 'previous_report_model.dart';

/// Filter categories for patient booking lists.
enum PatientBookingCategory {
  all('All'),
  onlineConsult('Online doctor appointment'),
  hospitalVisit('Hospital visit'),
  homeVisit('Home visit doctor'),
  nurse('Nurse visit'),
  scan('Scanning'),
  lab('Lab test'),
  ambulance('Ambulance'),
  bloodBank('Blood bank');

  const PatientBookingCategory(this.label);

  final String label;

  /// Sections shown on the My bookings tab, in display order.
  static const bookingSections = [
    PatientBookingCategory.onlineConsult,
    PatientBookingCategory.hospitalVisit,
    PatientBookingCategory.homeVisit,
    PatientBookingCategory.nurse,
    PatientBookingCategory.scan,
    PatientBookingCategory.lab,
    PatientBookingCategory.bloodBank,
    PatientBookingCategory.ambulance,
  ];

  static PatientBookingCategory resolve(PatientBookingModel booking) {
    for (final category in bookingSections) {
      if (category.matches(booking)) return category;
    }
    return PatientBookingCategory.onlineConsult;
  }

  bool matches(PatientBookingModel booking) {
    switch (this) {
      case PatientBookingCategory.all:
        return true;
      case PatientBookingCategory.onlineConsult:
        return booking.serviceType == 'doctor' && booking.isOnlineConsult;
      case PatientBookingCategory.hospitalVisit:
        return booking.serviceType == 'doctor' && booking.isClinicVisit;
      case PatientBookingCategory.homeVisit:
        return booking.serviceType == 'doctor' && booking.isHomeVisit;
      case PatientBookingCategory.nurse:
        return booking.serviceType == 'nurse';
      case PatientBookingCategory.scan:
        return booking.serviceType == 'scan' ||
            booking.consultationType == 'scan';
      case PatientBookingCategory.lab:
        return booking.serviceType == 'lab' || booking.consultationType == 'lab';
      case PatientBookingCategory.ambulance:
        return booking.serviceType == 'ambulance';
      case PatientBookingCategory.bloodBank:
        return booking.serviceType == 'blood_bank' ||
            booking.consultationType == 'blood_bank';
    }
  }
}

Map<PatientBookingCategory, List<PatientBookingModel>> groupBookingsByCategory(
  List<PatientBookingModel> bookings,
) {
  final grouped = {
    for (final category in PatientBookingCategory.bookingSections)
      category: <PatientBookingModel>[],
  };

  for (final booking in bookings) {
    final category = PatientBookingCategory.resolve(booking);
    grouped[category]!.add(booking);
  }

  return grouped;
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.parse(value);
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  throw FormatException('Invalid date: $value');
}

class PatientBookingStats {
  final int total;
  final int upcoming;
  final int past;

  const PatientBookingStats({
    required this.total,
    required this.upcoming,
    required this.past,
  });

  factory PatientBookingStats.fromJson(Map<String, dynamic> json) {
    return PatientBookingStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      past: (json['past'] as num?)?.toInt() ?? 0,
    );
  }
}

class PatientBookingModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String? doctorProfilePicture;
  final String serviceType;
  final String consultationType;
  final String typeLabel;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String label;
  final int? consultationFee;
  final String status;
  final String? paymentStatus;
  final double? distanceKm;
  final String? clinicName;
  final String? clinicAddress;
  final String? visitReason;
  final String? patientNotes;
  final String? patientAddress;
  final String? patientCity;
  final bool isUpcoming;
  final DateTime? createdAt;
  final String? appointmentCode;
  final DateTime? appointmentVerifiedAt;
  final bool canJoinVideo;
  final int? videoStartsInMinutes;
  final bool hasFeedback;
  final bool canRequestFeedback;
  final bool hasPrescription;
  final String? prescriptionPdfUrl;
  final String? prescriptionFileName;
  final bool prescriptionPending;
  final bool prescriptionProcessing;
  final List<PreviousReportModel> previousReports;

  const PatientBookingModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorProfilePicture,
    this.serviceType = 'doctor',
    required this.consultationType,
    required this.typeLabel,
    required this.slotStart,
    required this.slotEnd,
    required this.label,
    this.consultationFee,
    required this.status,
    this.paymentStatus,
    this.distanceKm,
    this.clinicName,
    this.clinicAddress,
    this.visitReason,
    this.patientNotes,
    this.patientAddress,
    this.patientCity,
    required this.isUpcoming,
    this.createdAt,
    this.appointmentCode,
    this.appointmentVerifiedAt,
    this.canJoinVideo = false,
    this.videoStartsInMinutes,
    this.hasFeedback = false,
    this.canRequestFeedback = false,
    this.hasPrescription = false,
    this.prescriptionPdfUrl,
    this.prescriptionFileName,
    this.prescriptionPending = false,
    this.prescriptionProcessing = false,
    this.previousReports = const [],
  });

  bool get isClinicVisit => consultationType == 'visit_site';

  bool get isHomeVisit => consultationType == 'book_home';

  bool get isOnlineConsult => consultationType == 'online_consult';

  bool get isPrescriptionEligible => isOnlineConsult || isHomeVisit;

  bool get isAwaitingDoctorApproval =>
      status == 'awaiting_doctor_approval';

  bool get isApprovedPendingPayment =>
      status == 'approved_pending_payment';

  bool get needsHomeVisitPayment =>
      isHomeVisit && isApprovedPendingPayment;

  String get statusLabel {
    if (isAwaitingDoctorApproval) {
      return 'Waiting for doctor approval';
    }
    if (isApprovedPendingPayment) {
      return 'Approved — pay to confirm';
    }
    if (status == 'confirmed') return 'Confirmed';
    if (status == 'cancelled') return 'Cancelled';
    return status;
  }

  bool get isAppointmentVerified => appointmentVerifiedAt != null;

  /// True while the appointment window has not ended yet.
  bool get isActiveOrUpcoming => !DateTime.now().isAfter(slotEnd);

  factory PatientBookingModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException('Missing booking id');
    }

    return PatientBookingModel(
      id: id,
      doctorId: (json['doctorId'] as String?) ??
          (json['nurseId'] as String?) ??
          '',
      doctorName: json['doctorName'] as String? ??
          json['labName'] as String? ??
          json['centerName'] as String? ??
          json['institutionName'] as String? ??
          'Provider',
      doctorProfilePicture: json['doctorProfilePicture'] as String?,
      serviceType: json['serviceType'] as String? ?? 'doctor',
      consultationType: json['consultationType'] as String? ?? 'online_consult',
      typeLabel: json['typeLabel'] as String? ?? 'Consultation',
      slotStart: _parseDateTime(json['slotStart']),
      slotEnd: _parseDateTime(json['slotEnd']),
      label: json['label'] as String? ?? '',
      consultationFee: (json['consultationFee'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'confirmed',
      paymentStatus: json['paymentStatus'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      clinicName: json['clinicName'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      visitReason: json['visitReason'] as String?,
      patientNotes: json['patientNotes'] as String?,
      patientAddress: json['patientAddress'] as String?,
      patientCity: json['patientCity'] as String?,
      isUpcoming: json['isUpcoming'] as bool? ??
          !_parseDateTime(json['slotEnd']).isBefore(DateTime.now()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      appointmentCode: json['appointmentCode'] as String?,
      appointmentVerifiedAt: json['appointmentVerifiedAt'] != null
          ? DateTime.tryParse(json['appointmentVerifiedAt'] as String)
          : null,
      canJoinVideo: json['canJoinVideo'] as bool? ?? false,
      videoStartsInMinutes: (json['videoStartsInMinutes'] as num?)?.toInt(),
      hasFeedback: json['hasFeedback'] as bool? ?? false,
      canRequestFeedback: json['canRequestFeedback'] as bool? ?? false,
      hasPrescription: json['hasPrescription'] as bool? ?? false,
      prescriptionPdfUrl: json['prescriptionPdfUrl'] as String?,
      prescriptionFileName: json['prescriptionFileName'] as String?,
      prescriptionPending: json['prescriptionPending'] as bool? ?? false,
      prescriptionProcessing: json['prescriptionProcessing'] as bool? ?? false,
      previousReports: (json['previousReports'] as List<dynamic>? ?? [])
          .map((e) => PreviousReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ConsultationBookingResult toConsultationResult() {
    return ConsultationBookingResult(
      id: id,
      doctorId: doctorId,
      consultationType: consultationType,
      doctorName: doctorName,
      patientName: '',
      patientMobile: '',
      slotStart: slotStart,
      slotEnd: slotEnd,
      label: label,
      consultationFee: consultationFee,
      status: status,
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      visitReason: visitReason,
      patientAddress: patientAddress,
      patientCity: patientCity,
      appointmentCode: appointmentCode,
      appointmentVerifiedAt: appointmentVerifiedAt,
    );
  }
}

class PatientBookingsResponse {
  final List<PatientBookingModel> bookings;
  final PatientBookingStats stats;

  const PatientBookingsResponse({
    required this.bookings,
    required this.stats,
  });

  factory PatientBookingsResponse.fromJson(Map<String, dynamic> json) {
    final bookings = <PatientBookingModel>[];
    for (final raw in json['bookings'] as List<dynamic>? ?? []) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        bookings.add(PatientBookingModel.fromJson(raw));
      } catch (_) {
        // Skip malformed rows so one bad booking does not hide the rest.
      }
    }
    final statsJson =
        json['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return PatientBookingsResponse(
      bookings: bookings,
      stats: PatientBookingStats.fromJson(statsJson),
    );
  }
}
