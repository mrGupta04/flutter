import 'dart:async';

import '../repositories/lab_repository.dart';
import '../repositories/scan_repository.dart';
import 'razorpay_checkout_service.dart';

/// Pays for an existing lab or scan booking via Razorpay (or mock).
class LabScanPaymentFlow {
  LabScanPaymentFlow({
    LabRepository? labRepository,
    ScanRepository? scanRepository,
    RazorpayCheckoutService? checkoutService,
  })  : _labRepo = labRepository ?? LabRepository(),
        _scanRepo = scanRepository ?? ScanRepository(),
        _checkout = checkoutService ?? RazorpayCheckoutService();

  final LabRepository _labRepo;
  final ScanRepository _scanRepo;
  final RazorpayCheckoutService _checkout;

  void dispose() => _checkout.dispose();

  Future<void> payLabBooking({
    required String bookingId,
    String businessName = 'Lab booking',
  }) async {
    final paymentRes = await _labRepo.createPaymentOrder(bookingId);
    if (!paymentRes.success || paymentRes.data == null) {
      throw Exception(paymentRes.error ?? 'Could not start payment');
    }
    await _openAndVerify(
      paymentData: paymentRes.data!,
      businessName: businessName,
      description: 'Lab test payment',
      verify: ({
        required String orderId,
        required String paymentId,
        required String signature,
      }) async {
        final verifyRes = await _labRepo.verifyPayment(
          bookingId: bookingId,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
        );
        if (!verifyRes.success) {
          throw Exception(verifyRes.error ?? 'Payment verification failed');
        }
      },
    );
  }

  Future<void> payScanBooking({
    required String bookingId,
    String businessName = 'Scan booking',
  }) async {
    final paymentRes = await _scanRepo.createPaymentOrder(bookingId);
    if (!paymentRes.success || paymentRes.data == null) {
      throw Exception(paymentRes.error ?? 'Could not start payment');
    }
    await _openAndVerify(
      paymentData: paymentRes.data!,
      businessName: businessName,
      description: 'Scan payment',
      verify: ({
        required String orderId,
        required String paymentId,
        required String signature,
      }) async {
        final verifyRes = await _scanRepo.verifyPayment(
          bookingId: bookingId,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
        );
        if (!verifyRes.success) {
          throw Exception(verifyRes.error ?? 'Payment verification failed');
        }
      },
    );
  }

  Future<void> _openAndVerify({
    required Map<String, dynamic> paymentData,
    required String businessName,
    required String description,
    required Future<void> Function({
      required String orderId,
      required String paymentId,
      required String signature,
    }) verify,
  }) async {
    final completer = Completer<void>();
    final razorpayOrderId = paymentData['razorpayOrderId']?.toString() ?? '';
    final amount = (paymentData['amount'] as num?)?.toInt() ?? 0;
    final currency = paymentData['currency']?.toString() ?? 'INR';
    final keyId = paymentData['keyId']?.toString();
    final mock = paymentData['mock'] == true;

    await _checkout.openCheckout(
      orderId: razorpayOrderId,
      amount: amount,
      currency: currency,
      keyId: keyId,
      mock: mock,
      businessName: businessName,
      description: description,
      prefillName: paymentData['prefillName']?.toString(),
      prefillEmail: paymentData['prefillEmail']?.toString(),
      prefillContact: paymentData['prefillContact']?.toString(),
      onSuccess: ({
        required String orderId,
        required String paymentId,
        required String signature,
      }) async {
        try {
          await verify(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          );
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      onFailure: (message) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(message));
        }
      },
    );

    await completer.future;
  }
}
