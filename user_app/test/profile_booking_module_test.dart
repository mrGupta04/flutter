import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/data/models/patient_booking_model.dart';
import 'package:user_app/features/user_dashboard/data/booking_status_config.dart';
import 'package:user_app/data/repositories/notifications_repository.dart';

PatientBookingModel _booking({
  required String status,
  String serviceType = 'doctor',
  String consultationType = 'online_consult',
  String? visitProgress,
  bool upcoming = true,
}) {
  final start = DateTime.utc(2026, 9, 12, 11, 0);
  return PatientBookingModel(
    id: 'b-$status',
    doctorId: 'doc-1',
    doctorName: 'Dr. Test',
    serviceType: serviceType,
    consultationType: consultationType,
    typeLabel: 'Consultation',
    slotStart: start,
    slotEnd: start.add(const Duration(minutes: 30)),
    label: '12 Sep 2026',
    status: status,
    visitProgress: visitProgress,
    isUpcoming: upcoming,
    canViewReceipt: status == 'completed',
  );
}

void main() {
  test('cancelled bookings map to history', () {
    final view = BookingStatusView.of(_booking(status: 'cancelled', upcoming: false));
    expect(view.bucket, BookingListBucket.history);
    expect(view.tone, BookingStatusTone.cancelled);
    expect(view.label, isNotEmpty);
  });

  test('pending payment maps to pending bucket', () {
    final view = BookingStatusView.of(
      _booking(status: 'approved_pending_payment'),
    );
    expect(view.bucket, BookingListBucket.pending);
  });

  test('terminal bookings are excluded from current', () {
    final completed = _booking(status: 'completed', upcoming: false);
    expect(completed.isActiveOrUpcoming, isFalse);
    expect(completed.isTerminal, isTrue);
  });

  test('history pagination json parses hasMore', () {
    final res = PatientBookingsResponse.fromJson({
      'bookings': [
        {
          'id': '1',
          'doctorName': 'Dr. A',
          'consultationType': 'online_consult',
          'typeLabel': 'Online consult',
          'slotStart': '2026-09-01T10:00:00.000Z',
          'slotEnd': '2026-09-01T10:30:00.000Z',
          'label': '1 Sep',
          'status': 'completed',
          'isUpcoming': false,
        },
      ],
      'stats': {'total': 40, 'upcoming': 2, 'past': 38},
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': 38,
        'totalPages': 2,
        'hasMore': true,
      },
    });
    expect(res.bookings, hasLength(1));
    expect(res.pagination.hasMore, isTrue);
    expect(res.pagination.total, 38);
  });

  test('notification category fallback', () {
    final n = AppNotification.fromJson({
      'id': 'n1',
      'title': 'Pay now',
      'body': 'Payment due',
      'type': 'payment_due',
    });
    expect(n.category, 'payment');
  });
}
