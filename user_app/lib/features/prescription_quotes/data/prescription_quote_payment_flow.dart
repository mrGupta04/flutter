import 'dart:async';

import '../../../data/services/razorpay_checkout_service.dart';
import 'prescription_request_repository.dart';

class PrescriptionQuotePaymentFlow {
  PrescriptionQuotePaymentFlow({
    PrescriptionRequestRepository? repository,
    RazorpayCheckoutService? checkoutService,
  })  : _repo = repository ?? PrescriptionRequestRepository(),
        _checkout = checkoutService ?? RazorpayCheckoutService();

  final PrescriptionRequestRepository _repo;
  final RazorpayCheckoutService _checkout;

  void dispose() => _checkout.dispose();

  Future<void> pay({
    required String requestId,
    String businessName = 'Lab quotation',
  }) async {
    final paymentRes = await _repo.createPaymentOrder(requestId);
    if (!paymentRes.success || paymentRes.data == null) {
      throw Exception(paymentRes.error ?? 'Could not start payment');
    }

    final paymentData = paymentRes.data!;
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
      description: 'Prescription lab quotation',
      prefillName: paymentData['prefillName']?.toString(),
      prefillEmail: paymentData['prefillEmail']?.toString(),
      prefillContact: paymentData['prefillContact']?.toString(),
      onSuccess: ({
        required String orderId,
        required String paymentId,
        required String signature,
      }) async {
        try {
          final verifyRes = await _repo.verifyPayment(
            requestId: requestId,
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
          );
          if (!verifyRes.success) {
            throw Exception(verifyRes.error ?? 'Payment verification failed');
          }
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      onFailure: (message) async {
        try {
          await _repo.markPaymentFailed(requestId);
        } catch (_) {}
        if (!completer.isCompleted) {
          completer.completeError(Exception(message));
        }
      },
    );

    await completer.future;
  }
}