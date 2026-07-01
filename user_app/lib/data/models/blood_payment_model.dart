class BloodPaymentOrderResponse {
  const BloodPaymentOrderResponse({
    required this.orderId,
    required this.razorpayOrderId,
    required this.amount,
    required this.amountInRupees,
    required this.currency,
    this.bloodBankName,
    this.keyId,
    this.paymentExpiresAt,
    this.mock = false,
    this.prefillName,
    this.prefillEmail,
    this.prefillContact,
  });

  final String orderId;
  final String razorpayOrderId;
  final int amount;
  final int amountInRupees;
  final String currency;
  final String? bloodBankName;
  final String? keyId;
  final DateTime? paymentExpiresAt;
  final bool mock;
  final String? prefillName;
  final String? prefillEmail;
  final String? prefillContact;

  factory BloodPaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    final prefill = json['prefill'] as Map<String, dynamic>? ?? {};
    return BloodPaymentOrderResponse(
      orderId: json['orderId'] as String,
      razorpayOrderId: json['orderRazorpayId'] as String? ?? json['orderId'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      amountInRupees: (json['amountInRupees'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      bloodBankName: json['bloodBankName'] as String?,
      keyId: json['keyId'] as String?,
      paymentExpiresAt: json['paymentExpiresAt'] != null
          ? DateTime.tryParse(json['paymentExpiresAt'].toString())
          : null,
      mock: json['mock'] as bool? ?? false,
      prefillName: prefill['name'] as String?,
      prefillEmail: prefill['email'] as String?,
      prefillContact: prefill['contact'] as String?,
    );
  }
}

class BloodPaymentVerifyRequest {
  const BloodPaymentVerifyRequest({
    required this.orderId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    this.razorpaySignature,
  });

  final String orderId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String? razorpaySignature;

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        if (razorpaySignature != null && razorpaySignature!.isNotEmpty)
          'razorpaySignature': razorpaySignature,
      };
}
