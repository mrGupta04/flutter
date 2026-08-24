import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/data/models/patient_booking_model.dart';
import 'package:user_app/features/nurse_home_visit/nurse_home_visit_navigation.dart';

PatientBookingModel bookingFrom({
  required String status,
  String serviceType = 'nurse',
  String consultationType = 'book_home',
  String? visitProgress,
}) {
  return PatientBookingModel.fromJson({
    'id': 'booking-1',
    'nurseId': 'nurse-1',
    'doctorName': 'Test Nurse',
    'serviceType': serviceType,
    'consultationType': consultationType,
    'typeLabel': 'Nurse home visit',
    'slotStart': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
    'slotEnd': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
    'label': 'Tomorrow 10:00 AM',
    'consultationFee': 499,
    'status': status,
    if (visitProgress != null) 'visitProgress': visitProgress,
    'isUpcoming': true,
  });
}

void main() {
  test('nurse approval shows payment, not live tracking', () {
    final booking = bookingFrom(status: 'payment_pending');

    expect(booking.needsHomeVisitPayment, isTrue);
    expect(booking.canTrackHomeVisitLive, isFalse);
    expect(booking.isActiveOrUpcoming, isTrue);
    expect(nursePaymentRoute(booking.id), '/nurse-payment?bookingId=booking-1');
  });

  test('legacy approved_pending_payment also needs dummy payment', () {
    final booking = bookingFrom(status: 'approved_pending_payment');
    expect(booking.needsHomeVisitPayment, isTrue);
    expect(booking.canTrackHomeVisitLive, isFalse);
  });

  test('paid nurse booking unlocks live tracking', () {
    final booking = bookingFrom(status: 'confirmed');

    expect(booking.needsHomeVisitPayment, isFalse);
    expect(booking.canTrackHomeVisitLive, isTrue);
    expect(nurseLiveTrackRoute(booking.id), '/home-visit-track?bookingId=booking-1');
  });

  test('waiting for nurse approval does not ask for payment', () {
    final booking = bookingFrom(status: 'pending_nurse_approval');
    expect(booking.needsHomeVisitPayment, isFalse);
    expect(booking.canTrackHomeVisitLive, isFalse);
  });
}
