import 'dart:async';

import '../models/blood_bank_model.dart';
import '../models/blood_payment_model.dart';
import '../repositories/blood_bank_repository.dart';
import 'razorpay_checkout_service.dart';

class BloodOrderPaymentFlow {
  BloodOrderPaymentFlow({
    BloodBankRepository? repository,
    RazorpayCheckoutService? checkoutService,
  })  : _repository = repository ?? BloodBankRepository(),
        _checkoutService = checkoutService ?? RazorpayCheckoutService();

  final BloodBankRepository _repository;
  final RazorpayCheckoutService _checkoutService;

  void dispose() => _checkoutService.dispose();

  Future<BloodOrderModel?> placeOrderWithPayment({
    required Map<String, dynamic> orderPayload,
    required BloodBankModel bloodBank,
  }) async {
    final payOnline = orderPayload['paymentMethod'] != 'cash';

    final placeRes = await _repository.placeOrder(orderPayload);
    if (!placeRes.success || placeRes.data == null) {
      throw Exception(placeRes.error ?? 'Could not place order');
    }

    final order = placeRes.data!;

    if (!payOnline) {
      return order;
    }

    final paymentRes = await _repository.createBloodPaymentOrder(order.id);
    if (!paymentRes.success || paymentRes.data == null) {
      throw Exception(paymentRes.error ?? 'Could not start payment');
    }

    final paymentOrder = paymentRes.data!;
    final completer = Completer<BloodOrderModel?>();

    await _checkoutService.openCheckout(
      orderId: paymentOrder.razorpayOrderId,
      amount: paymentOrder.amount,
      currency: paymentOrder.currency,
      keyId: paymentOrder.keyId,
      mock: paymentOrder.mock,
      businessName: bloodBank.displayName,
      description: 'Blood order — ${order.bloodGroup}',
      prefillName: paymentOrder.prefillName,
      prefillEmail: paymentOrder.prefillEmail,
      prefillContact: paymentOrder.prefillContact,
      onSuccess: ({
        required String orderId,
        required String paymentId,
        required String signature,
      }) async {
        try {
          final verifyRes = await _repository.verifyBloodPayment(
            BloodPaymentVerifyRequest(
              orderId: order.id,
              razorpayOrderId: orderId,
              razorpayPaymentId: paymentId,
              razorpaySignature: signature,
            ),
          );
          if (verifyRes.success && verifyRes.data != null) {
            if (!completer.isCompleted) completer.complete(verifyRes.data);
          } else if (!completer.isCompleted) {
            completer.completeError(
              Exception(verifyRes.error ?? 'Payment verification failed'),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      onFailure: (message) {
        if (!completer.isCompleted) completer.completeError(Exception(message));
      },
    );

    return completer.future;
  }
}
