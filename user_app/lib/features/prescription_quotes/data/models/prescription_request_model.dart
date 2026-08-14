class PrescriptionRequestedTest {
  const PrescriptionRequestedTest({required this.name, this.notes});

  final String name;
  final String? notes;

  factory PrescriptionRequestedTest.fromJson(Map<String, dynamic> json) {
    return PrescriptionRequestedTest(
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class PrescriptionQuotation {
  const PrescriptionQuotation({
    required this.id,
    required this.prescriptionRequestId,
    required this.labId,
    required this.labName,
    required this.status,
    required this.paymentStatus,
    this.providerType = 'lab',
    this.quotedAmount,
    this.estimatedCompletionTime,
    this.availableServices = const [],
    this.labNotes,
    this.rating,
    this.distanceKm,
    this.submittedAt,
    this.rejectionReason,
  });

  final String id;
  final String prescriptionRequestId;
  final String labId;
  final String labName;
  final String providerType;
  final double? quotedAmount;
  final String? estimatedCompletionTime;
  final List<String> availableServices;
  final String? labNotes;
  final double? rating;
  final double? distanceKm;
  final String status;
  final String paymentStatus;
  final DateTime? submittedAt;
  final String? rejectionReason;

  bool get isQuoted => status == 'QUOTED' || status == 'SELECTED';
  bool get isSelected => status == 'SELECTED';
  bool get isRejected => status == 'REJECTED';

  factory PrescriptionQuotation.fromJson(Map<String, dynamic> json) {
    return PrescriptionQuotation(
      id: json['id']?.toString() ?? '',
      prescriptionRequestId: json['prescriptionRequestId']?.toString() ?? '',
      labId: json['labId']?.toString() ?? '',
      labName: json['labName']?.toString() ?? 'Lab',
      providerType: json['providerType']?.toString() ?? 'lab',
      quotedAmount: (json['quotedAmount'] as num?)?.toDouble(),
      estimatedCompletionTime: json['estimatedCompletionTime']?.toString(),
      availableServices: (json['availableServices'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      labNotes: json['labNotes']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'PENDING',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class PrescriptionRequestModel {
  const PrescriptionRequestModel({
    required this.id,
    required this.userId,
    required this.prescriptionFileUrl,
    required this.prescriptionFileType,
    required this.status,
    required this.paymentStatus,
    required this.chatEnabled,
    this.patientName,
    this.patientMobile,
    this.patientEmail,
    this.prescriptionFileName,
    this.requestedTests = const [],
    this.notes,
    this.selectedLabId,
    this.selectedQuotationId,
    this.bookingId,
    this.quotations = const [],
    this.myQuotation,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? patientName;
  final String? patientMobile;
  final String? patientEmail;
  final String prescriptionFileUrl;
  final String prescriptionFileType;
  final String? prescriptionFileName;
  final List<PrescriptionRequestedTest> requestedTests;
  final String? notes;
  final String status;
  final String? selectedLabId;
  final String? selectedQuotationId;
  final String paymentStatus;
  final bool chatEnabled;
  final String? bookingId;
  final List<PrescriptionQuotation> quotations;
  final PrescriptionQuotation? myQuotation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get canChat => chatEnabled && paymentStatus == 'PAID';
  bool get canPay =>
      selectedQuotationId != null &&
      paymentStatus != 'PAID' &&
      (status == 'PAYMENT_PENDING' ||
          status == 'LAB_SELECTED' ||
          paymentStatus == 'FAILED' ||
          paymentStatus == 'PENDING');

  List<PrescriptionQuotation> get activeQuotations =>
      quotations.where((q) => q.isQuoted).toList();

  PrescriptionQuotation? get cheapestQuoted {
    final quoted = activeQuotations
        .where((q) => q.quotedAmount != null)
        .toList()
      ..sort((a, b) => a.quotedAmount!.compareTo(b.quotedAmount!));
    return quoted.isEmpty ? null : quoted.first;
  }

  factory PrescriptionRequestModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionRequestModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      patientName: json['patientName']?.toString(),
      patientMobile: json['patientMobile']?.toString(),
      patientEmail: json['patientEmail']?.toString(),
      prescriptionFileUrl: json['prescriptionFileUrl']?.toString() ?? '',
      prescriptionFileType: json['prescriptionFileType']?.toString() ?? '',
      prescriptionFileName: json['prescriptionFileName']?.toString(),
      requestedTests: (json['requestedTests'] as List?)
              ?.whereType<Map>()
              .map((e) => PrescriptionRequestedTest.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          const [],
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      selectedLabId: json['selectedLabId']?.toString(),
      selectedQuotationId: json['selectedQuotationId']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      chatEnabled: json['chatEnabled'] == true,
      bookingId: json['bookingId']?.toString(),
      quotations: (json['quotations'] as List?)
              ?.whereType<Map>()
              .map((e) => PrescriptionQuotation.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          const [],
      myQuotation: json['myQuotation'] is Map
          ? PrescriptionQuotation.fromJson(
              Map<String, dynamic>.from(json['myQuotation'] as Map),
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}