import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/doctor_model.dart';

/// Merges API document rows with URLs stored on the doctor profile.
List<DoctorDocumentModel> mergeAdminDocuments(
  DoctorModel doctor,
  List<DoctorDocumentModel> fromApi,
) {
  final byType = <DocumentType, DoctorDocumentModel>{};

  for (final doc in fromApi) {
    final type = doc.documentType;
    final url = doc.fileUrl;
    if (type != null && url != null && url.isNotEmpty) {
      if (_isHospitalPhotoType(type)) continue;
      byType[type] = doc;
    }
  }

  void addIfMissing(DocumentType type, String? url) {
    if (url == null || url.isEmpty || byType.containsKey(type)) return;
    byType[type] = DoctorDocumentModel(
      doctorId: doctor.id,
      documentType: type,
      fileUrl: url,
      fileName: url.split('/').last.split('?').first,
      status: DocumentStatus.pending,
    );
  }

  addIfMissing(DocumentType.medicalLicense, doctor.medicalLicenseUrl);
  addIfMissing(DocumentType.aadhaarCard, doctor.aadhaarCardUrl);
  addIfMissing(DocumentType.degreeCertificate, doctor.degreeCertificateUrl);
  addIfMissing(DocumentType.clinicProof, doctor.clinicProofUrl);
  addIfMissing(DocumentType.cancelledCheque, doctor.cancelledChequeUrl);

  final list = byType.values.toList();
  list.sort((a, b) => a.documentTypeDisplay.compareTo(b.documentTypeDisplay));
  return list;
}

bool _isHospitalPhotoType(DocumentType type) {
  switch (type) {
    case DocumentType.hospitalPhoto1:
    case DocumentType.hospitalPhoto2:
    case DocumentType.hospitalPhoto3:
    case DocumentType.hospitalPhoto4:
    case DocumentType.hospitalPhoto5:
      return true;
    default:
      return false;
  }
}
