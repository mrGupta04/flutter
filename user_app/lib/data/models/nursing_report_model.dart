class NursingReportModel {
  const NursingReportModel({
    required this.id,
    required this.bookingId,
    this.nurseId,
    this.patientId,
    this.pdfUrl,
    this.status,
    this.nurseNotes,
    this.submittedAt,
    this.finalizedAt,
    this.slotStart,
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final String? nurseId;
  final String? patientId;
  final String? pdfUrl;
  final String? status;
  final String? nurseNotes;
  final DateTime? submittedAt;
  final DateTime? finalizedAt;
  final DateTime? slotStart;
  final DateTime? createdAt;

  factory NursingReportModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return NursingReportModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      nurseId: json['nurseId']?.toString(),
      patientId: json['patientId']?.toString(),
      pdfUrl: json['pdfUrl'] as String?,
      status: json['status'] as String?,
      nurseNotes: json['nurseNotes'] as String?,
      submittedAt: parseDate(json['submittedAt']),
      finalizedAt: parseDate(json['finalizedAt']),
      slotStart: parseDate(json['slotStart']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
