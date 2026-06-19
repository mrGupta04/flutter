import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/payment_model.dart';

typedef PaymentSuccessHandler = void Function({
  required String orderId,
  required String paymentId,
  required String signature,
});

typedef PaymentFailureHandler = void Function(String message);

class RazorpayCheckoutService {
  Razorpay? _razorpay;
  PaymentSuccessHandler? _onSuccess;
  PaymentFailureHandler? _onFailure;

  bool get supportsNativeCheckout =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _onSuccess = null;
    _onFailure = null;
  }

  Future<void> openCheckout({
    required PaymentOrderResponse order,
    required PaymentSuccessHandler onSuccess,
    required PaymentFailureHandler onFailure,
  }) async {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    if (order.mock) {
      // Simulated checkout — no Razorpay keys required until env is configured.
      await Future.delayed(const Duration(milliseconds: 400));
      onSuccess(
        orderId: order.orderId,
        paymentId: 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
        signature: 'mock_signature',
      );
      return;
    }

    if (!supportsNativeCheckout) {
      onFailure(
        'Razorpay checkout is only supported on Android and iOS devices.',
      );
      return;
    }

    final keyId = order.keyId;
    if (keyId == null || keyId.isEmpty) {
      onFailure('Payment gateway is not configured on the server.');
      return;
    }

    _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = <String, dynamic>{
      'key': keyId,
      'amount': order.amount,
      'currency': order.currency,
      'name': order.doctorName ?? 'MedConnect Doctors',
      'description': 'Doctor consultation booking',
      'order_id': order.orderId,
      'prefill': {
        'name': order.prefillName,
        'email': order.prefillEmail,
        'contact': order.prefillContact,
      },
      'theme': {'color': '#0066CC'},
    };

    _razorpay!.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(
      orderId: response.orderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );
  }

  void _handleError(PaymentFailureResponse response) {
    final message = response.message ??
        response.error?['description'] as String? ??
        'Payment failed';
    _onFailure?.call(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onFailure?.call('External wallet selected: ${response.walletName}');
  }
}
