class BookableSlot {
  final int dayOfWeek;
  final int startHour;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String label;

  const BookableSlot({
    required this.dayOfWeek,
    required this.startHour,
    required this.slotStart,
    required this.slotEnd,
    required this.label,
  });

  factory BookableSlot.fromJson(Map<String, dynamic> json) {
    return BookableSlot(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
      startHour: (json['startHour'] as num?)?.toInt() ?? 8,
      slotStart: DateTime.parse(json['slotStart'] as String),
      slotEnd: DateTime.parse(json['slotEnd'] as String),
      label: json['label'] as String? ?? '',
    );
  }

  String get slotKey => '${dayOfWeek}_$startHour';

  /// Calendar date in local time — used to group slots in the booking UI.
  String get dateKey {
    final local = slotStart.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  DateTime get localSlotStart => slotStart.toLocal();

  DateTime get localSlotEnd => slotEnd.toLocal();
}

class BookableSlotsResponse {
  final String doctorId;
  final String? consultationType;
  final DateTime? weekStartDate;
  final DateTime? weekEndDate;
  final int? consultationFee;
  final List<BookableSlot> slots;
  final int? totalAvailableInWeek;
  final String? message;
  final String? clinicName;
  final String? clinicAddress;
  final String? clinicCity;
  final String? clinicState;
  final String? clinicPincode;

  const BookableSlotsResponse({
    required this.doctorId,
    this.consultationType,
    this.weekStartDate,
    this.weekEndDate,
    this.consultationFee,
    this.slots = const [],
    this.totalAvailableInWeek,
    this.message,
    this.clinicName,
    this.clinicAddress,
    this.clinicCity,
    this.clinicState,
    this.clinicPincode,
  });

  factory BookableSlotsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['slots'] as List? ?? [])
        .map((e) => BookableSlot.fromJson(e as Map<String, dynamic>))
        .toList();
    return BookableSlotsResponse(
      doctorId: (json['doctorId'] ?? json['nurseId']) as String? ?? '',
      consultationType: json['consultationType'] as String?,
      weekStartDate: _parseDate(json['weekStartDate']),
      weekEndDate: _parseDate(json['weekEndDate']),
      consultationFee: (json['consultationFee'] as num?)?.toInt(),
      slots: list,
      totalAvailableInWeek: (json['totalAvailableInWeek'] as num?)?.toInt(),
      message: json['message'] as String?,
      clinicName: json['clinicName'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      clinicCity: json['clinicCity'] as String?,
      clinicState: json['clinicState'] as String?,
      clinicPincode: json['clinicPincode'] as String?,
    );
  }
}

class ConsultationBookingResult {
  final String id;
  final String doctorId;
  final String consultationType;
  final String? doctorName;
  final String patientName;
  final String patientMobile;
  final String? patientEmail;
  final String? patientNotes;
  final String? patientAddress;
  final String? patientCity;
  final String? patientState;
  final String? patientPincode;
  final String? visitReason;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String label;
  final int? consultationFee;
  final String status;
  final String? clinicName;
  final String? clinicAddress;
  final String? appointmentCode;
  final DateTime? appointmentVerifiedAt;
  final double? distanceKm;

  const ConsultationBookingResult({
    required this.id,
    required this.doctorId,
    this.consultationType = 'online_consult',
    this.doctorName,
    required this.patientName,
    required this.patientMobile,
    this.patientEmail,
    this.patientNotes,
    this.patientAddress,
    this.patientCity,
    this.patientState,
    this.patientPincode,
    this.visitReason,
    required this.slotStart,
    required this.slotEnd,
    required this.label,
    this.consultationFee,
    required this.status,
    this.clinicName,
    this.clinicAddress,
    this.appointmentCode,
    this.appointmentVerifiedAt,
    this.distanceKm,
  });

  bool get isClinicVisit => consultationType == 'visit_site';

  bool get isAppointmentVerified => appointmentVerifiedAt != null;

  factory ConsultationBookingResult.fromJson(Map<String, dynamic> json) {
    return ConsultationBookingResult(
      id: json['id'] as String,
      doctorId: (json['doctorId'] ?? json['nurseId']) as String? ?? '',
      consultationType: json['consultationType'] as String? ?? 'online_consult',
      doctorName: (json['doctorName'] ?? json['nurseName']) as String?,
      patientName: json['patientName'] as String,
      patientMobile: json['patientMobile'] as String,
      patientEmail: json['patientEmail'] as String?,
      patientNotes: json['patientNotes'] as String?,
      patientAddress: json['patientAddress'] as String?,
      patientCity: json['patientCity'] as String?,
      patientState: json['patientState'] as String?,
      patientPincode: json['patientPincode'] as String?,
      visitReason: json['visitReason'] as String?,
      slotStart: DateTime.parse(json['slotStart'] as String),
      slotEnd: DateTime.parse(json['slotEnd'] as String),
      label: json['label'] as String? ?? '',
      consultationFee: (json['consultationFee'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'confirmed',
      clinicName: json['clinicName'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      appointmentCode: json['appointmentCode'] as String?,
      appointmentVerifiedAt: _parseDate(json['appointmentVerifiedAt']),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

typedef OnlineConsultBooking = ConsultationBookingResult;

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class SlotHoldResult {
  final String holdId;
  final DateTime? expiresAt;

  const SlotHoldResult({
    required this.holdId,
    this.expiresAt,
  });

  factory SlotHoldResult.fromJson(Map<String, dynamic> json) {
    return SlotHoldResult(
      holdId: json['holdId'] as String? ?? '',
      expiresAt: _parseDate(json['expiresAt']),
    );
  }
}
