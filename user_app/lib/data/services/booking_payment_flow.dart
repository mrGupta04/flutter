import 'dart:async';
import 'dart:typed_data';

import '../models/bookable_slot_model.dart';
import '../models/payment_model.dart';
import '../models/previous_report_model.dart';
import '../repositories/booking_reports_repository.dart';
import '../repositories/payment_repository.dart';
import 'razorpay_checkout_service.dart';

class BookingPaymentFlow {
  BookingPaymentFlow({
    PaymentRepository? paymentRepository,
    BookingReportsRepository? reportsRepository,
    RazorpayCheckoutService? checkoutService,
  })  : _paymentRepository = paymentRepository ?? PaymentRepository(),
        _reportsRepository = reportsRepository ?? BookingReportsRepository(),
        _checkoutService = checkoutService ?? RazorpayCheckoutService();

  final PaymentRepository _paymentRepository;
  final BookingReportsRepository _reportsRepository;
  final RazorpayCheckoutService _checkoutService;

  void dispose() {
    _checkoutService.dispose();
  }

  Future<ConsultationBookingResult?> payAndConfirm({
    required String doctorId,
    required String consultationType,
    required BookableSlot slot,
    required String patientName,
    required String patientMobile,
    String? patientEmail,
    String? patientNotes,
    String? patientAddress,
    String? patientCity,
    String? patientState,
    String? patientPincode,
    String? visitReason,
    List<PendingPreviousReport> previousReports = const [],
  }) async {
    final orderRes = await _paymentRepository.createOrder(
      doctorId: doctorId,
      consultationType: consultationType,
      patientName: patientName,
      patientMobile: patientMobile,
      patientEmail: patientEmail,
      patientNotes: patientNotes,
      patientAddress: patientAddress,
      patientCity: patientCity,
      patientState: patientState,
      patientPincode: patientPincode,
      visitReason: visitReason,
      dayOfWeek: slot.dayOfWeek,
      startHour: slot.startHour,
      slotStart: slot.slotStart,
    );

    if (!orderRes.success || orderRes.data == null) {
      throw Exception(orderRes.error ?? 'Could not start payment');
    }

    final order = orderRes.data!;

    if (previousReports.isNotEmpty) {
      await _uploadPreviousReports(order.bookingId, previousReports);
    }

    final completer = Completer<ConsultationBookingResult?>();

    await _checkoutService.openCheckout(
      order: order,
      onSuccess: ({
        required String orderId,
        required String paymentId,
        required String signature,
      }) async {
        try {
          final verifyRes = await _paymentRepository.verifyPayment(
            PaymentVerifyRequest(
              bookingId: order.bookingId,
              razorpayOrderId: orderId,
              razorpayPaymentId: paymentId,
              razorpaySignature: signature,
            ),
          );
          if (verifyRes.success && verifyRes.data != null) {
            if (!completer.isCompleted) {
              completer.complete(verifyRes.data);
            }
          } else if (!completer.isCompleted) {
            completer.completeError(
              Exception(verifyRes.error ?? 'Payment verification failed'),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      onFailure: (message) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(message));
        }
      },
    );

    return completer.future;
  }

  Future<ConsultationBookingResult?> payForExistingBooking({
    required String bookingId,
  }) async {
    final orderRes = await _paymentRepository.createOrderForBooking(
      bookingId: bookingId,
    );

    if (!orderRes.success || orderRes.data == null) {
      throw Exception(orderRes.error ?? 'Could not start payment');
    }

    final order = orderRes.data!;
    final completer = Completer<ConsultationBookingResult?>();

    await _checkoutService.openCheckout(
      order: order,
      onSuccess: ({
        required String orderId,
        required String paymentId,
        required String signature,
      }) async {
        try {
          final verifyRes = await _paymentRepository.verifyPayment(
            PaymentVerifyRequest(
              bookingId: order.bookingId,
              razorpayOrderId: orderId,
              razorpayPaymentId: paymentId,
              razorpaySignature: signature,
            ),
          );
          if (verifyRes.success && verifyRes.data != null) {
            if (!completer.isCompleted) {
              completer.complete(verifyRes.data);
            }
          } else if (!completer.isCompleted) {
            completer.completeError(
              Exception(verifyRes.error ?? 'Payment verification failed'),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      onFailure: (message) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(message));
        }
      },
    );

    return completer.future;
  }

  Future<void> _uploadPreviousReports(
    String bookingId,
    List<PendingPreviousReport> reports,
  ) async {
    for (final report in reports) {
      await _reportsRepository.uploadPreviousReport(
        bookingId: bookingId,
        bytes: Uint8List.fromList(report.bytes),
        fileName: report.fileName,
      );
    }
  }
}
