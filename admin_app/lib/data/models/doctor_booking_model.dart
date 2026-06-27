import 'previous_report_model.dart';

class DoctorBookingModel {
  const DoctorBookingModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    this.consultationType,
    this.typeLabel,
    this.patientName,
    this.patientMobile,
    this.patientEmail,
    this.patientNotes,
    this.patientAddress,
    this.patientCity,
    this.patientState,
    this.patientPincode,
    this.visitReason,
    this.consultationFee,
    this.appointmentCode,
    this.appointmentVerifiedAt,
    this.slotStart,
    this.slotEnd,
    this.isUpcoming = false,
    this.createdAt,
    this.canJoinVideo = false,
    this.videoStartsInMinutes,
    this.hasPrescription = false,
    this.prescriptionPdfUrl,
    this.prescriptionFileName,
    this.previousReports = const [],
    this.distanceKm,
    this.paymentStatus,
  });

  final double? distanceKm;
  final String? paymentStatus;

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String? consultationType;
  final String? typeLabel;
  final String? patientName;
  final String? patientMobile;
  final String? patientEmail;
  final String? patientNotes;
  final String? patientAddress;
  final String? patientCity;
  final String? patientState;
  final String? patientPincode;
  final String? visitReason;
  final int? consultationFee;
  final String? appointmentCode;
  final DateTime? appointmentVerifiedAt;
  final DateTime? slotStart;
  final DateTime? slotEnd;
  final bool isUpcoming;
  final DateTime? createdAt;
  final bool canJoinVideo;
  final int? videoStartsInMinutes;
  final bool hasPrescription;
  final String? prescriptionPdfUrl;
  final String? prescriptionFileName;
  final List<PreviousReportModel> previousReports;

  bool get isOnlineConsult => consultationType == 'online_consult';
  bool get isClinicVisit => consultationType == 'visit_site';
  bool get isAppointmentVerified => appointmentVerifiedAt != null;
  bool get isHomeVisit => consultationType == 'book_home';

  bool get isAwaitingDoctorApproval =>
      status == 'awaiting_doctor_approval';

  bool get isApprovedPendingPayment =>
      status == 'approved_pending_payment';

  String get displayStatusLabel {
    if (isAwaitingDoctorApproval) return 'Awaiting your approval';
    if (isApprovedPendingPayment) return 'Awaiting patient payment';
    if (status == 'confirmed') return 'Confirmed';
    if (status == 'cancelled') return 'Cancelled';
    return status.toUpperCase();
  }

  String get displayTypeLabel {
    if (typeLabel != null && typeLabel!.isNotEmpty) return typeLabel!;
    if (isOnlineConsult) return 'Online consult';
    if (isClinicVisit) return 'Clinic visit';
    if (isHomeVisit) return 'Home visit';
    return 'Consultation';
  }

  String? get patientLocationLine {
    final parts = [
      patientAddress,
      patientCity,
      patientState,
      patientPincode,
    ].where((p) => p != null && p.trim().isNotEmpty).map((p) => p!.trim());
    final joined = parts.join(', ');
    return joined.isEmpty ? null : joined;
  }

  factory DoctorBookingModel.fromJson(Map<String, dynamic> json) {
    return DoctorBookingModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Booking',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? 'confirmed',
      paymentStatus: json['paymentStatus'] as String?,
      consultationType: json['consultationType'] as String?,
      typeLabel: json['typeLabel'] as String?,
      patientName: json['patientName'] as String?,
      patientMobile: json['patientMobile'] as String?,
      patientEmail: json['patientEmail'] as String?,
      patientNotes: json['patientNotes'] as String?,
      patientAddress: json['patientAddress'] as String?,
      patientCity: json['patientCity'] as String?,
      patientState: json['patientState'] as String?,
      patientPincode: json['patientPincode'] as String?,
      visitReason: json['visitReason'] as String?,
      consultationFee: _parseInt(json['consultationFee']),
      appointmentCode: json['appointmentCode'] as String?,
      appointmentVerifiedAt: _parseDate(json['appointmentVerifiedAt']),
      slotStart: _parseDate(json['slotStart']),
      slotEnd: _parseDate(json['slotEnd']),
      isUpcoming: json['isUpcoming'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      canJoinVideo: json['canJoinVideo'] as bool? ?? false,
      videoStartsInMinutes: (json['videoStartsInMinutes'] as num?)?.toInt(),
      hasPrescription: json['hasPrescription'] as bool? ?? false,
      prescriptionPdfUrl: json['prescriptionPdfUrl'] as String?,
      prescriptionFileName: json['prescriptionFileName'] as String?,
      previousReports: (json['previousReports'] as List<dynamic>? ?? [])
          .map((e) => PreviousReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class DoctorBookingStats {
  const DoctorBookingStats({
    this.total = 0,
    this.upcoming = 0,
    this.today = 0,
    this.upcomingOnline = 0,
    this.upcomingClinic = 0,
    this.upcomingHome = 0,
    this.past = 0,
  });

  final int total;
  final int upcoming;
  final int today;
  final int upcomingOnline;
  final int upcomingClinic;
  final int upcomingHome;
  final int past;

  static DoctorBookingStats fromBookings(List<DoctorBookingModel> bookings) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    var upcoming = 0;
    var today = 0;
    var upcomingOnline = 0;
    var upcomingClinic = 0;
    var upcomingHome = 0;
    var past = 0;

    for (final booking in bookings) {
      final slot = booking.slotStart;
      final isFuture = booking.isUpcoming && (slot == null || !slot.isBefore(now));

      if (isFuture) {
        upcoming++;
        if (booking.isOnlineConsult) upcomingOnline++;
        if (booking.isClinicVisit) upcomingClinic++;
        if (booking.isHomeVisit) upcomingHome++;
      } else {
        past++;
      }

      if (slot != null &&
          !slot.isBefore(todayStart) &&
          slot.isBefore(todayEnd)) {
        today++;
      }
    }

    return DoctorBookingStats(
      total: bookings.length,
      upcoming: upcoming,
      today: today,
      upcomingOnline: upcomingOnline,
      upcomingClinic: upcomingClinic,
      upcomingHome: upcomingHome,
      past: past,
    );
  }
}
