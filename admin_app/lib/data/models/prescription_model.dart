class PrescriptionMedicineModel {
  const PrescriptionMedicineModel({
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
  });

  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (dosage != null && dosage!.isNotEmpty) 'dosage': dosage,
        if (frequency != null && frequency!.isNotEmpty) 'frequency': frequency,
        if (duration != null && duration!.isNotEmpty) 'duration': duration,
        if (instructions != null && instructions!.isNotEmpty)
          'instructions': instructions,
      };

  factory PrescriptionMedicineModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicineModel(
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      duration: json['duration'] as String?,
      instructions: json['instructions'] as String?,
    );
  }
}

class PrescriptionTestModel {
  const PrescriptionTestModel({
    required this.name,
    this.notes,
  });

  final String name;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  factory PrescriptionTestModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionTestModel(
      name: json['name'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class PrescriptionModel {
  const PrescriptionModel({
    required this.id,
    required this.bookingId,
    required this.patientName,
    this.patientEmail,
    this.symptoms,
    this.diagnosis,
    this.medicines = const [],
    this.tests = const [],
    this.advice,
    this.status = 'draft',
    this.pdfUrl,
    this.pdfFileName,
    this.doctorName,
    this.slotLabel,
  });

  final String id;
  final String bookingId;
  final String patientName;
  final String? patientEmail;
  final String? symptoms;
  final String? diagnosis;
  final List<PrescriptionMedicineModel> medicines;
  final List<PrescriptionTestModel> tests;
  final String? advice;
  final String status;
  final String? pdfUrl;
  final String? pdfFileName;
  final String? doctorName;
  final String? slotLabel;

  bool get isFinalized => status == 'finalized';

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      patientEmail: json['patientEmail'] as String?,
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      medicines: (json['medicines'] as List<dynamic>? ?? [])
          .map((e) => PrescriptionMedicineModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList(),
      tests: (json['tests'] as List<dynamic>? ?? [])
          .map((e) => PrescriptionTestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      advice: json['advice'] as String?,
      status: json['status'] as String? ?? 'draft',
      pdfUrl: json['pdfUrl'] as String?,
      pdfFileName: json['pdfFileName'] as String?,
      doctorName: json['doctorName'] as String?,
      slotLabel: json['slotLabel'] as String?,
    );
  }
}

class PrescriptionContextModel {
  const PrescriptionContextModel({
    required this.bookingId,
    required this.patientName,
    this.patientEmail,
    this.symptoms,
    this.slotLabel,
    this.doctorName,
    this.prescription,
  });

  final String bookingId;
  final String patientName;
  final String? patientEmail;
  final String? symptoms;
  final String? slotLabel;
  final String? doctorName;
  final PrescriptionModel? prescription;

  factory PrescriptionContextModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionContextModel(
      bookingId: json['bookingId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      patientEmail: json['patientEmail'] as String?,
      symptoms: json['symptoms'] as String?,
      slotLabel: json['slotLabel'] as String?,
      doctorName: json['doctorName'] as String?,
      prescription: json['prescription'] != null
          ? PrescriptionModel.fromJson(
              json['prescription'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PrescriptionSaveResult {
  const PrescriptionSaveResult({
    required this.prescription,
    this.emailSent = false,
    this.emailReason,
  });

  final PrescriptionModel prescription;
  final bool emailSent;
  final String? emailReason;

  factory PrescriptionSaveResult.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as Map<String, dynamic>? ?? {};
    return PrescriptionSaveResult(
      prescription: PrescriptionModel.fromJson(
        json['prescription'] as Map<String, dynamic>? ?? {},
      ),
      emailSent: email['sent'] as bool? ?? false,
      emailReason: email['reason'] as String?,
    );
  }
}
