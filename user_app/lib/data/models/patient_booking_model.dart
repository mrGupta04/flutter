import 'package:flutter/material.dart';

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

  IconData get icon {
    switch (this) {
      case PatientBookingCategory.onlineConsult:
        return Icons.videocam_rounded;
      case PatientBookingCategory.hospitalVisit:
        return Icons.local_hospital_rounded;
      case PatientBookingCategory.homeVisit:
        return Icons.home_rounded;
      case PatientBookingCategory.nurse:
        return Icons.health_and_safety_rounded;
      case PatientBookingCategory.scan:
        return Icons.radar_rounded;
      case PatientBookingCategory.lab:
        return Icons.biotech_rounded;
      case PatientBookingCategory.ambulance:
        return Icons.emergency_rounded;
      case PatientBookingCategory.bloodBank:
        return Icons.bloodtype_rounded;
      case PatientBookingCategory.all:
        return Icons.grid_view_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PatientBookingCategory.onlineConsult:
        return const Color(0xFF007A5E);
      case PatientBookingCategory.hospitalVisit:
        return const Color(0xFF00897B);
      case PatientBookingCategory.homeVisit:
        return const Color(0xFF3949AB);
      case PatientBookingCategory.nurse:
        return const Color(0xFF5E35B1);
      case PatientBookingCategory.scan:
        return const Color(0xFF0288D1);
      case PatientBookingCategory.lab:
        return const Color(0xFFE65100);
      case PatientBookingCategory.ambulance:
        return const Color(0xFFD32F2F);
      case PatientBookingCategory.bloodBank:
        return const Color(0xFFC2185B);
      case PatientBookingCategory.all:
        return const Color(0xFF007A5E);
    }
  }

  String get sectionTitle {
    switch (this) {
      case PatientBookingCategory.onlineConsult:
        return 'Online Doctor Consultations';
      case PatientBookingCategory.hospitalVisit:
        return 'Hospital & Clinic Visits';
      case PatientBookingCategory.homeVisit:
        return 'Doctor Home Visits';
      case PatientBookingCategory.nurse:
        return 'Nurse Home Visits';
      case PatientBookingCategory.scan:
        return 'Diagnostic Scans & Imaging';
      case PatientBookingCategory.lab:
        return 'Lab Tests & Diagnostics';
      case PatientBookingCategory.ambulance:
        return 'Ambulance Services';
      case PatientBookingCategory.bloodBank:
        return 'Blood Bank Requests';
      case PatientBookingCategory.all:
        return 'All Bookings';
    }
  }

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
        return (booking.serviceType == 'doctor' &&
                (booking.isOnlineConsult ||
                    (!booking.isClinicVisit && !booking.isHomeVisit))) ||
            booking.consultationType == 'online_consult';
      case PatientBookingCategory.hospitalVisit:
        return (booking.serviceType == 'doctor' && booking.isClinicVisit) ||
            booking.consultationType == 'visit_site';
      case PatientBookingCategory.homeVisit:
        return (booking.serviceType == 'doctor' && booking.isHomeVisit) ||
            booking.consultationType == 'book_home';
      case PatientBookingCategory.nurse:
        return booking.serviceType == 'nurse' ||
            booking.consultationType == 'nurse_visit';
      case PatientBookingCategory.scan:
        return booking.serviceType == 'scan' ||
            booking.consultationType == 'scan';
      case PatientBookingCategory.lab:
        return booking.serviceType == 'lab' || booking.consultationType == 'lab';
      case PatientBookingCategory.ambulance:
        return booking.serviceType == 'ambulance' ||
            booking.consultationType == 'ambulance';
      case PatientBookingCategory.bloodBank:
        return booking.serviceType == 'blood_bank' ||
            booking.consultationType == 'blood_bank';
    }
  }

  String? get apiServiceType {
    switch (this) {
      case PatientBookingCategory.all:
        return null;
      case PatientBookingCategory.onlineConsult:
      case PatientBookingCategory.hospitalVisit:
      case PatientBookingCategory.homeVisit:
        return 'doctor';
      case PatientBookingCategory.nurse:
        return 'nurse';
      case PatientBookingCategory.scan:
        return 'scan';
      case PatientBookingCategory.lab:
        return 'lab';
      case PatientBookingCategory.ambulance:
        return 'ambulance';
      case PatientBookingCategory.bloodBank:
        return 'blood_bank';
    }
  }

  String? get apiConsultationType {
    switch (this) {
      case PatientBookingCategory.onlineConsult:
        return 'online_consult';
      case PatientBookingCategory.hospitalVisit:
        return 'visit_site';
      case PatientBookingCategory.homeVisit:
        return 'book_home';
      default:
        return null;
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

DateTime? _tryParseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  if (value is num) {
    final raw = value.toInt();
    if (raw <= 0) return null;
    final milliseconds = raw < 1000000000000 ? raw * 1000 : raw;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  return null;
}

DateTime? _firstDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _tryParseDateTime(json[key]);
    if (parsed != null) return parsed;
  }
  return null;
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

class BookingTimelineStep {
  final String key;
  final String label;
  final bool done;
  final DateTime? at;

  const BookingTimelineStep({
    required this.key,
    required this.label,
    required this.done,
    this.at,
  });

  factory BookingTimelineStep.fromJson(Map<String, dynamic> json) {
    return BookingTimelineStep(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      done: json['done'] as bool? ?? false,
      at: json['at'] != null ? DateTime.tryParse(json['at'].toString()) : null,
    );
  }
}

class PatientBookingModel {
  final String id;
  final String doctorId;
  final String? nurseId;
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
  final String? visitProgress;
  final DateTime? paymentExpiresAt;
  final int? remainingPaymentSeconds;
  final DateTime? serverTime;
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
  final String? verificationStatus;
  final bool canJoinVideo;
  final int? videoStartsInMinutes;
  final bool hasFeedback;
  final bool canRequestFeedback;
  final bool hasPrescription;
  final String? prescriptionPdfUrl;
  final String? prescriptionFileName;
  final bool prescriptionPending;
  final bool prescriptionProcessing;
  final bool hasVisitNote;
  final String? nursingReportPdfUrl;
  final bool nursingReportLocked;
  final List<PreviousReportModel> previousReports;
  final List<BookingTimelineStep> timeline;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? liveLatitude;
  final double? liveLongitude;
  final DateTime? liveLocationUpdatedAt;
  final int? amountPaid;
  final String? paymentMethod;
  final String? paymentReference;
  final DateTime? paidAt;
  final String? currency;
  final bool canViewReceipt;
  final String? invoiceUrl;

  const PatientBookingModel({
    required this.id,
    required this.doctorId,
    this.nurseId,
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
    this.visitProgress,
    this.paymentExpiresAt,
    this.remainingPaymentSeconds,
    this.serverTime,
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
    this.verificationStatus,
    this.canJoinVideo = false,
    this.videoStartsInMinutes,
    this.hasFeedback = false,
    this.canRequestFeedback = false,
    this.hasPrescription = false,
    this.prescriptionPdfUrl,
    this.prescriptionFileName,
    this.prescriptionPending = false,
    this.prescriptionProcessing = false,
    this.hasVisitNote = false,
    this.nursingReportPdfUrl,
    this.nursingReportLocked = false,
    this.previousReports = const [],
    this.timeline = const [],
    this.pickupLatitude,
    this.pickupLongitude,
    this.liveLatitude,
    this.liveLongitude,
    this.liveLocationUpdatedAt,
    this.amountPaid,
    this.paymentMethod,
    this.paymentReference,
    this.paidAt,
    this.currency,
    this.canViewReceipt = false,
    this.invoiceUrl,
  });

  bool get canTrackAmbulanceLive {
    if (serviceType != 'ambulance') return false;
    const liveStatuses = {
      'accepted',
      'dispatched',
      'en_route',
      'arrived',
      'searching_ambulance',
      'ambulance_assigned',
      'driver_accepted',
      'driver_en_route',
      'arrived_at_pickup',
      'patient_picked_up',
      'en_route_to_destination',
      'arrived_at_destination',
    };
    return liveStatuses.contains(status);
  }

  bool get canTrackHomeVisitLive {
    if (!isHomeVisit && !isNurseVisit) return false;
    if (status == 'cancelled' || status == 'rejected') return false;
    if (visitProgress == 'completed') return false;
    return status == 'confirmed' ||
        visitProgress == 'en_route' ||
        visitProgress == 'arrived' ||
        visitProgress == 'visit_started';
  }
  bool get isClinicVisit => consultationType == 'visit_site';

  bool get isHomeVisit => consultationType == 'book_home';

  bool get isOnlineConsult => consultationType == 'online_consult';

  bool get isNurseVisit => serviceType == 'nurse';

  bool get isPrescriptionEligible => isOnlineConsult || isHomeVisit;

  bool get isAwaitingDoctorApproval =>
      status == 'awaiting_doctor_approval' ||
      status == 'pending_nurse_approval';

  bool get isApprovedPendingPayment =>
      status == 'approved_pending_payment' ||
      status == 'payment_pending';

  bool get needsHomeVisitPayment =>
      (isHomeVisit || isNurseVisit) && isApprovedPendingPayment;

  /// Lab/scan confirmed (or requested) but still unpaid online.
  bool get needsLabOrScanPayment {
    if (serviceType != 'lab' && serviceType != 'scan') return false;
    if (paymentStatus == 'paid' || paymentStatus == 'pay_at_lab' || paymentStatus == 'pay_at_center') {
      return false;
    }
    return paymentStatus == 'pending' &&
        (status == 'confirmed' ||
            status == 'pending' ||
            status == 'requested');
  }

  bool get isConfirmed => status == 'confirmed';

  bool get canChat {
    if (serviceType == 'lab') {
      return const {
        'confirmed',
        'sample_collected',
        'processing',
        'report_ready',
      }.contains(status);
    }
    if (serviceType == 'scan') {
      return const {
        'confirmed',
        'in_progress',
        'report_ready',
      }.contains(status);
    }
    if (serviceType == 'ambulance') {
      return canTrackAmbulanceLive;
    }
    return isConfirmed;
  }

  bool get canCancel =>
      isAwaitingDoctorApproval ||
      isApprovedPendingPayment ||
      status == 'pending' ||
      isConfirmed;

  String get providerId =>
      (isNurseVisit ? nurseId : doctorId) ?? doctorId;

  String get statusLabel {
    if (serviceType == 'lab') {
      if (status == 'pending' || status == 'requested') {
        return 'Waiting for lab confirmation';
      }
      if (status == 'confirmed') return 'Lab confirmed';
      if (status == 'sample_collected') return 'Sample collected';
      if (status == 'processing') return 'Processing';
      if (status == 'report_ready') return 'Report ready';
      if (status == 'completed') return 'Completed';
      if (status == 'cancelled') return 'Cancelled';
      if (status == 'rejected') return 'Rejected by lab';
    }
    if (serviceType == 'scan') {
      if (status == 'pending' || status == 'requested') {
        return 'Waiting for scan center confirmation';
      }
      if (status == 'confirmed') return 'Scan confirmed';
      if (status == 'in_progress') return 'Scan in progress';
      if (status == 'report_ready') return 'Report ready';
      if (status == 'completed') return 'Completed';
      if (status == 'cancelled') return 'Cancelled';
      if (status == 'rejected') return 'Rejected by center';
    }
    if (serviceType == 'ambulance') {
      if (status == 'pending' || status == 'requested') {
        return 'Ambulance requested';
      }
      if (status == 'searching_ambulance') return 'Searching ambulance';
      if (status == 'ambulance_assigned' || status == 'driver_accepted') {
        return 'Ambulance assigned';
      }
      if (status == 'accepted') return 'Ambulance accepted';
      if (status == 'dispatched' ||
          status == 'driver_en_route' ||
          status == 'en_route') {
        return 'Ambulance on the way';
      }
      if (status == 'arrived' || status == 'arrived_at_pickup') {
        return 'Ambulance arrived';
      }
      if (status == 'patient_picked_up') return 'Patient picked up';
      if (status == 'en_route_to_destination') return 'Going to destination';
      if (status == 'arrived_at_destination') return 'Reached destination';
      if (status == 'completed' || status == 'trip_completed') {
        return 'Trip completed';
      }
      if (status == 'cancelled') return 'Cancelled';
      if (status == 'rejected') return 'Request declined';
    }
    if (serviceType == 'blood_bank') {
      if (status == 'pending' ||
          status == 'requested' ||
          status == 'under_review' ||
          status == 'emergency_requested') {
        return 'Blood request pending';
      }
      if (status == 'response_received') return 'Blood bank responded';
      if (status == 'accepted') return 'Blood request accepted';
      if (status == 'reserved' || status == 'blood_reserved') {
        return 'Blood reserved';
      }
      if (status == 'ready') return 'Ready for collection';
      if (status == 'completed' ||
          status == 'delivered' ||
          status == 'collected') {
        return 'Completed';
      }
      if (status == 'cancelled') return 'Cancelled';
      if (status == 'rejected') return 'Rejected';
    }
    if (isAwaitingDoctorApproval) {
      return isNurseVisit
          ? 'Waiting for nurse approval'
          : 'Waiting for doctor approval';
    }
    if (isApprovedPendingPayment) {
      return 'Approved — pay to confirm';
    }
    if (status == 'payment_expired') {
      return 'Payment expired';
    }
    if (status == 'nurse_rejected') {
      return 'Nurse declined';
    }
    if (isClinicVisit && visitProgress == 'completed') return 'Completed';
    if (isClinicVisit && visitProgress == 'visit_started') {
      return 'Consultation started';
    }
    if (isClinicVisit && isAppointmentVerified) return 'Patient Verified ✓';
    if (isClinicVisit && status == 'confirmed') {
      return 'Waiting for Clinic Verification';
    }
    if (visitProgress == 'en_route') {
      return isNurseVisit ? 'Nurse on the way' : 'Doctor on the way';
    }
    if (visitProgress == 'arrived') return 'Provider arrived';
    if (visitProgress == 'visit_started') {
      return isNurseVisit ? 'Nurse visit in progress' : 'Visit in progress';
    }
    if (visitProgress == 'completed') return 'Visit completed';
    if (status == 'confirmed') return 'Confirmed';
    if (status == 'cancelled') return 'Cancelled';
    return status;
  }

  bool get isAppointmentVerified =>
      appointmentVerifiedAt != null || verificationStatus == 'VERIFIED';

  bool get isTerminal {
    const terminal = {
      'cancelled',
      'rejected',
      'nurse_rejected',
      'payment_expired',
      'completed',
      'trip_completed',
      'failed',
      'expired',
      'no_answer',
      'report_ready',
      'delivered',
      'collected',
      'closed',
    };
    if (terminal.contains(status)) return true;
    return visitProgress == 'completed';
  }

  bool get isPendingRequest {
    if (isTerminal) return false;
    return isAwaitingDoctorApproval ||
        isApprovedPendingPayment ||
        status == 'pending' ||
        status == 'requested' ||
        status == 'held' ||
        status == 'searching_ambulance' ||
        status == 'under_review' ||
        status == 'emergency_requested' ||
        status == 'response_received';
  }

  bool get isOpenWorkflow {
    if (isTerminal) return false;
    return const {
      'accepted',
      'reserved',
      'blood_reserved',
      'ready',
      'ambulance_assigned',
      'driver_accepted',
    }.contains(status);
  }

  bool get isLiveNow {
    if (isTerminal || isPendingRequest) return false;
    if (canTrackAmbulanceLive) return true;
    if (const {'en_route', 'arrived', 'visit_started'}.contains(visitProgress)) {
      return true;
    }
    if (serviceType == 'lab' &&
        const {'sample_collected', 'processing'}.contains(status)) {
      return true;
    }
    if (serviceType == 'scan' && status == 'in_progress') return true;
    if (isClinicVisit && isAppointmentVerified) return true;
    return false;
  }

  /// True while the booking still belongs in the current profile tabs.
  bool get isActiveOrUpcoming {
    if (isTerminal) return false;
    if (isPendingRequest || isLiveNow || isOpenWorkflow) return true;
    return isUpcoming || !DateTime.now().isAfter(slotEnd);
  }

  PatientBookingCategory get category => PatientBookingCategory.resolve(this);

  factory PatientBookingModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException('Missing booking id');
    }

    final timelineRaw = json['timeline'] as List<dynamic>? ?? [];
    final createdAt = _tryParseDateTime(json['createdAt']);
    final slotStart = _firstDateTime(json, const [
          'slotStart',
          'scheduledAt',
          'scheduledDate',
          'requiredDate',
          'appointmentDate',
          'createdAt',
        ]) ??
        createdAt ??
        DateTime.now();
    final slotEnd = _firstDateTime(json, const [
          'slotEnd',
          'scheduledEnd',
          'endsAt',
          'endTime',
        ]) ??
        slotStart.add(const Duration(hours: 2));

    final serviceType = json['serviceType'] as String? ?? 'doctor';
    final consultationType =
        json['consultationType'] as String? ?? 'online_consult';

    String? extractNonEmpty(dynamic val) {
      if (val is String && val.trim().isNotEmpty) return val.trim();
      return null;
    }

    String doctorName = extractNonEmpty(json['doctorName']) ??
        extractNonEmpty(json['nurseName']) ??
        extractNonEmpty(json['labName']) ??
        extractNonEmpty(json['scanCenterName']) ??
        extractNonEmpty(json['centerName']) ??
        extractNonEmpty(json['ambulanceServiceName']) ??
        extractNonEmpty(json['hospitalName']) ??
        extractNonEmpty(json['providerName']) ??
        extractNonEmpty(json['institutionName']) ??
        '';

    if (doctorName.isEmpty || doctorName.toLowerCase() == 'provider') {
      switch (serviceType) {
        case 'ambulance':
          doctorName = 'Ambulance Service';
          break;
        case 'lab':
          doctorName = 'Diagnostic Lab';
          break;
        case 'scan':
          doctorName = 'Scan Centre';
          break;
        case 'blood_bank':
          doctorName = 'Blood Bank';
          break;
        case 'nurse':
          doctorName = 'Home Visit Nurse';
          break;
        case 'doctor':
          doctorName = 'Doctor Consultation';
          break;
        default:
          doctorName = 'Healthcare Provider';
      }
    }

    String typeLabel = extractNonEmpty(json['typeLabel']) ?? '';
    if (typeLabel.isEmpty || typeLabel.toLowerCase() == 'consultation') {
      switch (serviceType) {
        case 'ambulance':
          typeLabel = json['isEmergency'] == true
              ? 'Emergency ambulance'
              : 'Ambulance';
          break;
        case 'lab':
          typeLabel = json['collectionType'] == 'home_collection'
              ? 'Lab home collection'
              : 'Lab visit';
          break;
        case 'scan':
          typeLabel = 'Diagnostic scan';
          break;
        case 'blood_bank':
          typeLabel = json['isEmergency'] == true
              ? 'Emergency blood request'
              : 'Blood request';
          break;
        case 'nurse':
          typeLabel = 'Nurse home visit';
          break;
        case 'doctor':
          typeLabel = consultationType == 'visit_site'
              ? 'Clinic visit'
              : consultationType == 'book_home'
                  ? 'Doctor home visit'
                  : 'Online consult';
          break;
        default:
          typeLabel = 'Consultation';
      }
    }

    return PatientBookingModel(
      id: id,
      doctorId: (json['doctorId'] as String?) ??
          (json['nurseId'] as String?) ??
          '',
      nurseId: json['nurseId'] as String?,
      doctorName: doctorName,
      doctorProfilePicture: json['doctorProfilePicture'] as String?,
      serviceType: serviceType,
      consultationType: consultationType,
      typeLabel: typeLabel,
      slotStart: slotStart,
      slotEnd: slotEnd,
      label: json['label'] as String? ?? '',
      consultationFee: (json['consultationFee'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'confirmed',
      paymentStatus: json['paymentStatus'] as String?,
      visitProgress: json['visitProgress'] as String?,
      paymentExpiresAt: _tryParseDateTime(json['paymentExpiresAt']),
      remainingPaymentSeconds:
          (json['remainingPaymentSeconds'] as num?)?.toInt(),
      serverTime: _tryParseDateTime(json['serverTime']),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      clinicName: json['clinicName'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      visitReason: json['visitReason'] as String?,
      patientNotes: json['patientNotes'] as String?,
      patientAddress: json['patientAddress'] as String?,
      patientCity: json['patientCity'] as String?,
      isUpcoming: json['isUpcoming'] as bool? ??
          !slotEnd.isBefore(DateTime.now()),
      createdAt: createdAt,
      appointmentCode: json['appointmentCode'] as String?,
      appointmentVerifiedAt: _tryParseDateTime(json['appointmentVerifiedAt']),
      verificationStatus: json['verificationStatus'] as String?,
      canJoinVideo: json['canJoinVideo'] as bool? ?? false,
      videoStartsInMinutes: (json['videoStartsInMinutes'] as num?)?.toInt(),
      hasFeedback: json['hasFeedback'] as bool? ?? false,
      canRequestFeedback: json['canRequestFeedback'] as bool? ?? false,
      hasPrescription: json['hasPrescription'] as bool? ?? false,
      prescriptionPdfUrl: json['prescriptionPdfUrl'] as String?,
      prescriptionFileName: json['prescriptionFileName'] as String?,
      prescriptionPending: json['prescriptionPending'] as bool? ?? false,
      prescriptionProcessing: json['prescriptionProcessing'] as bool? ?? false,
      hasVisitNote: json['hasVisitNote'] as bool? ?? false,
      nursingReportPdfUrl: json['nursingReportPdfUrl'] as String?,
      nursingReportLocked: json['nursingReportLocked'] as bool? ?? false,
      previousReports: (json['previousReports'] as List<dynamic>? ?? [])
          .map((e) => PreviousReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: timelineRaw
          .whereType<Map>()
          .map((e) => BookingTimelineStep.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      liveLatitude: (json['liveLatitude'] as num?)?.toDouble(),
      liveLongitude: (json['liveLongitude'] as num?)?.toDouble(),
      liveLocationUpdatedAt: _tryParseDateTime(json['liveLocationUpdatedAt']),
      amountPaid: (json['amountPaid'] as num?)?.toInt() ??
          (json['consultationFee'] as num?)?.toInt(),
      paymentMethod: json['paymentMethod'] as String?,
      paymentReference: json['paymentReference'] as String?,
      paidAt: _tryParseDateTime(json['paidAt']),
      currency: json['currency'] as String? ?? 'INR',
      canViewReceipt: json['canViewReceipt'] as bool? ?? false,
      invoiceUrl: json['invoiceUrl'] as String?,
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

class BookingListPagination {
  const BookingListPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
    this.hasMore = false,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  factory BookingListPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingListPagination();
    return BookingListPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class PatientBookingsResponse {
  final List<PatientBookingModel> bookings;
  final PatientBookingStats stats;
  final BookingListPagination pagination;

  const PatientBookingsResponse({
    required this.bookings,
    required this.stats,
    this.pagination = const BookingListPagination(),
  });

  factory PatientBookingsResponse.fromJson(Map<String, dynamic> json) {
    final bookings = <PatientBookingModel>[];
    for (final raw in json['bookings'] as List<dynamic>? ?? []) {
      if (raw is! Map) continue;
      try {
        bookings.add(
          PatientBookingModel.fromJson(Map<String, dynamic>.from(raw)),
        );
      } catch (_) {
        // Skip malformed rows so one bad booking does not hide the rest.
      }
    }
    final statsJson =
        json['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final paginationJson = json['pagination'] as Map<String, dynamic>?;
    return PatientBookingsResponse(
      bookings: bookings,
      stats: PatientBookingStats.fromJson(statsJson),
      pagination: BookingListPagination.fromJson(paginationJson),
    );
  }
}
