class PreviousReportModel {
  const PreviousReportModel({
    required this.id,
    required this.fileUrl,
    this.fileName,
    this.mimeType,
    this.uploadedAt,
  });

  final String id;
  final String fileUrl;
  final String? fileName;
  final String? mimeType;
  final DateTime? uploadedAt;

  String get displayName {
    if (fileName != null && fileName!.trim().isNotEmpty) return fileName!.trim();
    final parts = fileUrl.split('/');
    return parts.isNotEmpty ? parts.last : 'Report';
  }

  bool get isPdf =>
      mimeType == 'application/pdf' ||
      displayName.toLowerCase().endsWith('.pdf');

  factory PreviousReportModel.fromJson(Map<String, dynamic> json) {
    return PreviousReportModel(
      id: json['id'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String?,
      mimeType: json['mimeType'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String)
          : null,
    );
  }
}

/// Local file picked by the patient before upload.
class PendingPreviousReport {
  const PendingPreviousReport({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  final List<int> bytes;
  final String fileName;
  final String? mimeType;
}
