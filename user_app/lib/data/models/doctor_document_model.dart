/// Document type enumeration
enum DocumentType {
  medicalLicense,
  governmentId,
  degreeCertificate,
  clinicProof,
  cancelledCheque,
}

/// Document status enumeration
enum DocumentStatus {
  pending,
  verified,
  rejected,
  underReview,
}

/// Doctor document model
class DoctorDocumentModel {
  final String? id;
  final String? doctorId;
  final DocumentType? documentType;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final DocumentStatus? status;
  final String? rejectionReason;
  final DateTime? uploadedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  DoctorDocumentModel({
    this.id,
    this.doctorId,
    this.documentType,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.status,
    this.rejectionReason,
    this.uploadedAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  /// Get document type display name
  String get documentTypeDisplay {
    switch (documentType) {
      case DocumentType.medicalLicense:
        return 'Medical License';
      case DocumentType.governmentId:
        return 'Government ID';
      case DocumentType.degreeCertificate:
        return 'Degree Certificate';
      case DocumentType.clinicProof:
        return 'Clinic Proof';
      case DocumentType.cancelledCheque:
        return 'Cancelled Cheque';
      default:
        return 'Document';
    }
  }

  /// Get status display name
  String get statusDisplay {
    switch (status) {
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.underReview:
        return 'Under Review';
      case DocumentStatus.pending:
      default:
        return 'Pending';
    }
  }

  factory DoctorDocumentModel.fromJson(Map<String, dynamic> json) {
    return DoctorDocumentModel(
      id: json['id'] as String?,
      doctorId: json['doctorId'] as String?,
      documentType: _parseDocumentType(json['documentType'] as String?),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
      status: _parseDocumentStatus(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String)
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
      verifiedBy: json['verifiedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'documentType': _documentTypeToJson(documentType),
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'status': _documentStatusToJson(status),
      'rejectionReason': rejectionReason,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  /// Create a copy with updated fields
  DoctorDocumentModel copyWith({
    String? id,
    String? doctorId,
    DocumentType? documentType,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    DocumentStatus? status,
    String? rejectionReason,
    DateTime? uploadedAt,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return DoctorDocumentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      documentType: documentType ?? this.documentType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
}

DocumentType? _parseDocumentType(String? value) {
  switch (value) {
    case 'medical_license':
      return DocumentType.medicalLicense;
    case 'government_id':
      return DocumentType.governmentId;
    case 'degree_certificate':
      return DocumentType.degreeCertificate;
    case 'clinic_proof':
      return DocumentType.clinicProof;
    case 'cancelled_cheque':
      return DocumentType.cancelledCheque;
    default:
      return null;
  }
}

String? _documentTypeToJson(DocumentType? type) {
  switch (type) {
    case DocumentType.medicalLicense:
      return 'medical_license';
    case DocumentType.governmentId:
      return 'government_id';
    case DocumentType.degreeCertificate:
      return 'degree_certificate';
    case DocumentType.clinicProof:
      return 'clinic_proof';
    case DocumentType.cancelledCheque:
      return 'cancelled_cheque';
    default:
      return null;
  }
}

DocumentStatus? _parseDocumentStatus(String? value) {
  switch (value) {
    case 'pending':
      return DocumentStatus.pending;
    case 'verified':
      return DocumentStatus.verified;
    case 'rejected':
      return DocumentStatus.rejected;
    case 'under_review':
      return DocumentStatus.underReview;
    default:
      return null;
  }
}

String? _documentStatusToJson(DocumentStatus? status) {
  switch (status) {
    case DocumentStatus.pending:
      return 'pending';
    case DocumentStatus.verified:
      return 'verified';
    case DocumentStatus.rejected:
      return 'rejected';
    case DocumentStatus.underReview:
      return 'under_review';
    default:
      return null;
  }
}
