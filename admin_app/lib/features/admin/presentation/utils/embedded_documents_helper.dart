import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/lab_model.dart';
import '../../../../data/models/scan_center_model.dart';

DocumentStatus? embeddedDocumentStatus(String? verificationStatus) {
  switch (verificationStatus) {
    case 'verified':
      return DocumentStatus.verified;
    case 'rejected':
      return DocumentStatus.rejected;
    case 'under_review':
      return DocumentStatus.underReview;
    case 'pending':
    default:
      return DocumentStatus.pending;
  }
}

DoctorDocumentModel embeddedDocumentToAdminDoc({
  required String id,
  required String type,
  required String label,
  required String url,
  String? verificationStatus,
  String? rejectionReason,
}) {
  return DoctorDocumentModel(
    id: id,
    rawDocumentType: type,
    displayLabel: label,
    fileUrl: url,
    fileName: label,
    status: embeddedDocumentStatus(verificationStatus),
    rejectionReason: rejectionReason,
  );
}

List<DoctorDocumentModel> labDocumentsToAdminDocs(List<LabDocument>? docs) {
  return (docs ?? const [])
      .where((doc) => doc.url.trim().isNotEmpty)
      .map(
        (doc) => embeddedDocumentToAdminDoc(
          id: doc.id,
          type: doc.type,
          label: doc.label,
          url: doc.url,
          verificationStatus: doc.verificationStatus,
          rejectionReason: doc.rejectionReason,
        ),
      )
      .toList(growable: false);
}

List<DoctorDocumentModel> scanDocumentsToAdminDocs(
  List<ScanCenterDocument>? docs,
) {
  return (docs ?? const [])
      .where((doc) => doc.url.trim().isNotEmpty)
      .map(
        (doc) => embeddedDocumentToAdminDoc(
          id: doc.id,
          type: doc.type,
          label: doc.label,
          url: doc.url,
          verificationStatus: doc.verificationStatus,
          rejectionReason: doc.rejectionReason,
        ),
      )
      .toList(growable: false);
}

List<DoctorDocumentModel> bloodBankDocumentsToAdminDocs(
  List<BloodBankDocument>? docs,
) {
  return (docs ?? const [])
      .where((doc) => doc.url.trim().isNotEmpty)
      .map(
        (doc) => embeddedDocumentToAdminDoc(
          id: doc.id,
          type: doc.type,
          label: doc.label,
          url: doc.url,
          verificationStatus: doc.verificationStatus,
          rejectionReason: doc.rejectionReason,
        ),
      )
      .toList(growable: false);
}
