import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/patient_booking_model.dart';

enum BookingStatusTone {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  failed,
}

enum BookingListBucket {
  active,
  upcoming,
  pending,
  history,
}

class BookingStatusView {
  const BookingStatusView({
    required this.label,
    required this.tone,
    required this.icon,
    required this.bucket,
  });

  final String label;
  final BookingStatusTone tone;
  final IconData icon;
  final BookingListBucket bucket;

  Color get color {
    switch (tone) {
      case BookingStatusTone.pending:
        return AppColors.warning;
      case BookingStatusTone.confirmed:
        return const Color(0xFF2563EB);
      case BookingStatusTone.inProgress:
        return const Color(0xFF7C3AED);
      case BookingStatusTone.completed:
        return AppColors.success;
      case BookingStatusTone.cancelled:
      case BookingStatusTone.failed:
        return AppColors.error;
    }
  }

  Color get background => color.withValues(alpha: 0.12);

  factory BookingStatusView.of(PatientBookingModel booking) {
    final status = booking.status;
    final progress = booking.visitProgress;
    final service = booking.serviceType;

    if (_cancelledStatuses.contains(status)) {
      return BookingStatusView(
        label: status == 'nurse_rejected'
            ? 'Nurse declined'
            : status == 'rejected'
                ? 'Rejected'
                : 'Cancelled',
        tone: BookingStatusTone.cancelled,
        icon: Icons.cancel_outlined,
        bucket: BookingListBucket.history,
      );
    }
    if (_failedStatuses.contains(status)) {
      return BookingStatusView(
        label: status == 'payment_expired' ? 'Payment expired' : 'Failed',
        tone: BookingStatusTone.failed,
        icon: Icons.error_outline_rounded,
        bucket: BookingListBucket.history,
      );
    }
    if (progress == 'completed' ||
        status == 'completed' ||
        status == 'trip_completed') {
      return const BookingStatusView(
        label: 'Completed',
        tone: BookingStatusTone.completed,
        icon: Icons.check_circle_outline_rounded,
        bucket: BookingListBucket.history,
      );
    }
    if (status == 'report_ready') {
      return const BookingStatusView(
        label: 'Report ready',
        tone: BookingStatusTone.completed,
        icon: Icons.description_outlined,
        bucket: BookingListBucket.history,
      );
    }

    if (booking.isAwaitingDoctorApproval) {
      return BookingStatusView(
        label: booking.isNurseVisit
            ? 'Waiting for nurse'
            : 'Waiting for provider',
        tone: BookingStatusTone.pending,
        icon: Icons.hourglass_empty_rounded,
        bucket: BookingListBucket.pending,
      );
    }
    if (booking.isApprovedPendingPayment) {
      return const BookingStatusView(
        label: 'Payment pending',
        tone: BookingStatusTone.pending,
        icon: Icons.payments_outlined,
        bucket: BookingListBucket.pending,
      );
    }
    if (status == 'pending' ||
        status == 'requested' ||
        status == 'held' ||
        status == 'searching_ambulance') {
      return BookingStatusView(
        label: service == 'ambulance' ? 'Searching ambulance' : 'Pending',
        tone: BookingStatusTone.pending,
        icon: Icons.schedule_rounded,
        bucket: BookingListBucket.pending,
      );
    }

    if (booking.canTrackAmbulanceLive ||
        progress == 'en_route' ||
        progress == 'arrived' ||
        progress == 'visit_started' ||
        status == 'sample_collected' ||
        status == 'processing' ||
        status == 'in_progress' ||
        status == 'driver_en_route' ||
        status == 'patient_picked_up' ||
        status == 'en_route_to_destination') {
      return BookingStatusView(
        label: _inProgressLabel(booking),
        tone: BookingStatusTone.inProgress,
        icon: Icons.directions_run_rounded,
        bucket: BookingListBucket.active,
      );
    }

    if (booking.isClinicVisit && booking.isAppointmentVerified) {
      return const BookingStatusView(
        label: 'Checked in',
        tone: BookingStatusTone.inProgress,
        icon: Icons.verified_outlined,
        bucket: BookingListBucket.active,
      );
    }

    final slotPassed = DateTime.now().isAfter(booking.slotEnd);
    if (slotPassed && !booking.isConfirmed) {
      return const BookingStatusView(
        label: 'Completed',
        tone: BookingStatusTone.completed,
        icon: Icons.check_circle_outline_rounded,
        bucket: BookingListBucket.history,
      );
    }

    return BookingStatusView(
      label: _confirmedLabel(booking),
      tone: BookingStatusTone.confirmed,
      icon: Icons.event_available_rounded,
      bucket: slotPassed ? BookingListBucket.history : BookingListBucket.upcoming,
    );
  }

  static String _inProgressLabel(PatientBookingModel booking) {
    if (booking.serviceType == 'ambulance') return 'On the way';
    if (booking.visitProgress == 'arrived') return 'Provider arrived';
    if (booking.visitProgress == 'visit_started') {
      return booking.isNurseVisit ? 'Visit in progress' : 'In progress';
    }
    if (booking.visitProgress == 'en_route') {
      return booking.isNurseVisit ? 'Nurse on the way' : 'Doctor on the way';
    }
    if (booking.status == 'processing') return 'Processing';
    if (booking.status == 'sample_collected') return 'Sample collected';
    if (booking.status == 'in_progress') return 'In progress';
    return 'In progress';
  }

  static String _confirmedLabel(PatientBookingModel booking) {
    if (booking.serviceType == 'lab') return 'Lab confirmed';
    if (booking.serviceType == 'scan') return 'Scan confirmed';
    if (booking.isClinicVisit) return 'Clinic visit confirmed';
    return 'Confirmed';
  }
}

const _cancelledStatuses = {
  'cancelled',
  'rejected',
  'nurse_rejected',
};

const _failedStatuses = {
  'payment_expired',
  'failed',
  'expired',
  'no_answer',
};
