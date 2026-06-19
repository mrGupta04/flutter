class PaymentOrderResponse {
  const PaymentOrderResponse({
    required this.bookingId,
    required this.orderId,
    required this.amount,
    required this.amountInRupees,
    required this.currency,
    this.keyId,
    this.doctorName,
    this.consultationType,
    this.consultationFee,
    this.paymentExpiresAt,
    this.mock = false,
    this.prefillName,
    this.prefillEmail,
    this.prefillContact,
  });

  final String bookingId;
  final String orderId;
  final int amount;
  final int amountInRupees;
  final String currency;
  final String? keyId;
  final String? doctorName;
  final String? consultationType;
  final int? consultationFee;
  final DateTime? paymentExpiresAt;
  final bool mock;
  final String? prefillName;
  final String? prefillEmail;
  final String? prefillContact;

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    final prefill = json['prefill'] as Map<String, dynamic>? ?? {};
    return PaymentOrderResponse(
      bookingId: json['bookingId'] as String,
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      amountInRupees: (json['amountInRupees'] as num?)?.toInt() ??
          (json['consultationFee'] as num?)?.toInt() ??
          0,
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['keyId'] as String?,
      doctorName: json['doctorName'] as String?,
      consultationType: json['consultationType'] as String?,
      consultationFee: (json['consultationFee'] as num?)?.toInt(),
      paymentExpiresAt: _parseDate(json['paymentExpiresAt']),
      mock: json['mock'] as bool? ?? false,
      prefillName: prefill['name'] as String?,
      prefillEmail: prefill['email'] as String?,
      prefillContact: prefill['contact'] as String?,
    );
  }
}

class PaymentVerifyRequest {
  const PaymentVerifyRequest({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    this.razorpaySignature,
  });

  final String bookingId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String? razorpaySignature;

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        if (razorpaySignature != null && razorpaySignature!.isNotEmpty)
          'razorpaySignature': razorpaySignature,
      };
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
