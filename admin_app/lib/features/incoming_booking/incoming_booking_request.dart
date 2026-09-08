import '../../core/utils/validation_utils.dart';
import '../../data/models/doctor_booking_model.dart';

/// Provider-agnostic incoming booking request shown in the urgent overlay.
///
/// Reuse this model for doctors, nurses, and later labs/ambulance/hospitals.
class IncomingBookingRequest {
  const IncomingBookingRequest({
    required this.bookingId,
    required this.providerRole,
    required this.patientName,
    required this.serviceType,
    required this.status,
    required this.shownAt,
    this.bookingDate,
    this.timeLabel,
    this.locationLine,
    this.approvalExpiresAt,
    this.alertExpiresAt,
    this.alertSeconds = 90,
  });

  final String bookingId;
  final String providerRole;
  final String patientName;
  final String serviceType;
  final String status;
  final DateTime shownAt;
  final DateTime? bookingDate;
  final String? timeLabel;
  final String? locationLine;
  final DateTime? approvalExpiresAt;
  final DateTime? alertExpiresAt;
  final int alertSeconds;

  bool get isPending {
    final value = status.toLowerCase();
    return value == 'awaiting_doctor_approval' ||
        value == 'pending_nurse_approval' ||
        value == 'pending' ||
        value == 'requested' ||
        value == 'searching_ambulance';
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'awaiting_doctor_approval':
      case 'pending_nurse_approval':
      case 'pending':
      case 'requested':
      case 'searching_ambulance':
        return 'Awaiting your response';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      case 'approved_pending_payment':
      case 'payment_pending':
        return 'Accepted';
      case 'nurse_rejected':
        return 'Rejected';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String get dateLabel {
    if (bookingDate != null) {
      return FormattingUtils.formatDate(bookingDate!);
    }
    return '—';
  }

  String get displayTime {
    if (timeLabel != null && timeLabel!.trim().isNotEmpty) {
      final raw = timeLabel!.trim();
      final parts = raw.split('•');
      if (parts.length > 1) return parts.last.trim();
      return raw;
    }
    if (bookingDate != null) {
      return FormattingUtils.formatTime(bookingDate!);
    }
    return '—';
  }

  DateTime get ringDeadline {
    if (alertExpiresAt != null) return alertExpiresAt!;
    final fromSeconds = shownAt.add(Duration(seconds: alertSeconds));
    if (approvalExpiresAt != null && approvalExpiresAt!.isBefore(fromSeconds)) {
      return approvalExpiresAt!;
    }
    return fromSeconds;
  }

  int get remainingSeconds {
    final left = ringDeadline.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  IncomingBookingRequest copyWith({
    String? status,
    DateTime? alertExpiresAt,
  }) {
    return IncomingBookingRequest(
      bookingId: bookingId,
      providerRole: providerRole,
      patientName: patientName,
      serviceType: serviceType,
      status: status ?? this.status,
      shownAt: shownAt,
      bookingDate: bookingDate,
      timeLabel: timeLabel,
      locationLine: locationLine,
      approvalExpiresAt: approvalExpiresAt,
      alertExpiresAt: alertExpiresAt ?? this.alertExpiresAt,
      alertSeconds: alertSeconds,
    );
  }

  static bool isIncomingType(String? type, [Map<String, dynamic>? data]) {
    final t = (type ?? '').toLowerCase();
    final action = (data?['action'] ?? '').toString().toLowerCase();
    return t == 'home_visit_request' ||
        t == 'ambulance_emergency' ||
        t == 'ambulance_request_created' ||
        action == 'home_visit_request' ||
        action == 'incoming_booking_request';
  }

  static bool isExpiryType(String? type, [Map<String, dynamic>? data]) {
    final t = (type ?? '').toLowerCase();
    final action = (data?['action'] ?? '').toString().toLowerCase();
    final status = (data?['status'] ?? '').toString().toLowerCase();
    return action == 'booking_expired' ||
        status == 'expired' ||
        (t == 'booking_cancelled' && action == 'booking_expired');
  }

  static bool isPendingStatus(String? status) {
    final value = (status ?? '').toLowerCase();
    return value == 'awaiting_doctor_approval' ||
        value == 'pending_nurse_approval' ||
        value == 'pending' ||
        value == 'requested' ||
        value == 'searching_ambulance';
  }

  factory IncomingBookingRequest.fromBooking(
    DoctorBookingModel booking, {
    required String providerRole,
  }) {
    final service = providerRole == 'nurse'
        ? 'Home Nurse Visit'
        : booking.displayTypeLabel == 'Home visit'
            ? 'Home Doctor Visit'
            : booking.displayTypeLabel;
    return IncomingBookingRequest(
      bookingId: booking.id,
      providerRole: providerRole,
      patientName: booking.patientName?.trim().isNotEmpty == true
          ? booking.patientName!.trim()
          : 'Patient',
      serviceType: service,
      status: booking.status,
      shownAt: DateTime.now(),
      bookingDate: booking.slotStart,
      timeLabel: booking.slotStart != null
          ? FormattingUtils.formatTime(booking.slotStart!)
          : booking.subtitle,
      locationLine: booking.patientLocationLine ??
          (booking.isHomeVisit ? 'Patient Home' : null),
      approvalExpiresAt: booking.approvalExpiresAt,
    );
  }

  factory IncomingBookingRequest.fromPayload(
    Map<String, dynamic> payload, {
    String fallbackRole = 'doctor',
  }) {
    final nested = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : const <String, dynamic>{};
    final merged = <String, dynamic>{...nested, ...payload};
    if (nested.isNotEmpty) {
      merged.addAll(nested);
    }
    final bookingId = merged['bookingId']?.toString() ?? '';
    final role = (merged['providerRole'] ??
            merged['userType'] ??
            fallbackRole)
        .toString()
        .toLowerCase();
    final normalizedRole = role == 'nurse'
        ? 'nurse'
        : role == 'ambulance' || role == 'ambulance_driver'
            ? 'ambulance'
            : 'doctor';
    final date = _parseDate(merged['date'] ?? merged['slotStart']);
    final alertSeconds = int.tryParse(
          merged['alertSeconds']?.toString() ?? '',
        ) ??
        90;
    return IncomingBookingRequest(
      bookingId: bookingId,
      providerRole: normalizedRole,
      patientName: (merged['patientName'] ?? 'Patient').toString().trim(),
      serviceType: (merged['service'] ??
              (normalizedRole == 'nurse'
                  ? 'Home Nurse Visit'
                  : normalizedRole == 'ambulance'
                      ? 'Emergency ambulance'
                      : 'Home Doctor Visit'))
          .toString(),
      status: (merged['status'] ?? 'awaiting_doctor_approval').toString(),
      shownAt: DateTime.now(),
      bookingDate: date,
      timeLabel: merged['time']?.toString(),
      locationLine: merged['location']?.toString(),
      approvalExpiresAt: _parseDate(merged['approvalExpiresAt']),
      alertExpiresAt: _parseDate(merged['alertExpiresAt']),
      alertSeconds: alertSeconds,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value > 9999999999 ? value : value * 1000,
      );
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
