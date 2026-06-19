import '../../../../data/models/ambulance_model.dart';
import '../../../../data/models/doctor_document_model.dart';

List<DoctorDocumentModel> mergeAmbulanceDocuments(
  AmbulanceModel ambulance,
  List<DoctorDocumentModel> fromApi,
) {
  final byKey = <String, DoctorDocumentModel>{};

  String keyOf(DoctorDocumentModel doc) =>
      '${doc.rawDocumentType ?? doc.documentType}:${doc.vehicleId ?? ''}:${doc.driverId ?? ''}';

  for (final doc in fromApi) {
    if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty) {
      byKey[keyOf(doc)] = doc;
    }
  }

  void addIfMissing({
    required String type,
    String? url,
    String? vehicleId,
    String? driverId,
  }) {
    if (url == null || url.isEmpty) return;
    final key = '$type:${vehicleId ?? ''}:${driverId ?? ''}';
    if (byKey.containsKey(key)) return;
    byKey[key] = DoctorDocumentModel(
      ambulanceId: ambulance.id,
      rawDocumentType: type,
      fileUrl: url,
      fileName: url.split('/').last.split('?').first,
      vehicleId: vehicleId,
      driverId: driverId,
      status: DocumentStatus.pending,
    );
  }

  addIfMissing(type: 'serviceLicense', url: ambulance.serviceLicenseUrl);
  addIfMissing(type: 'companyRegistration', url: ambulance.companyRegistrationUrl);
  addIfMissing(type: 'gstCertificate', url: ambulance.gstCertificateUrl);
  addIfMissing(type: 'fleetInsurance', url: ambulance.fleetInsuranceUrl);
  addIfMissing(type: 'cancelledCheque', url: ambulance.cancelledChequeUrl);

  for (final vehicle in ambulance.vehicles ?? []) {
    addIfMissing(type: 'rcBook', url: vehicle.rcBookUrl, vehicleId: vehicle.id);
    addIfMissing(type: 'insurance', url: vehicle.insuranceUrl, vehicleId: vehicle.id);
    addIfMissing(
      type: 'fitnessCertificate',
      url: vehicle.fitnessCertificateUrl,
      vehicleId: vehicle.id,
    );
    addIfMissing(
      type: 'pollutionCertificate',
      url: vehicle.pollutionCertificateUrl,
      vehicleId: vehicle.id,
    );
    addIfMissing(type: 'photoFront', url: vehicle.photoFrontUrl, vehicleId: vehicle.id);
    addIfMissing(type: 'photoBack', url: vehicle.photoBackUrl, vehicleId: vehicle.id);
    addIfMissing(
      type: 'photoInterior',
      url: vehicle.photoInteriorUrl,
      vehicleId: vehicle.id,
    );
  }

  for (final driver in ambulance.drivers ?? []) {
    addIfMissing(
      type: 'governmentId',
      url: driver.governmentIdUrl,
      driverId: driver.id,
    );
    addIfMissing(
      type: 'drivingLicense',
      url: driver.drivingLicenseUrl,
      driverId: driver.id,
    );
    addIfMissing(
      type: 'emtCertificate',
      url: driver.emtCertificateUrl,
      driverId: driver.id,
    );
    addIfMissing(type: 'photo', url: driver.photoUrl, driverId: driver.id);
  }

  final list = byKey.values.toList();
  list.sort((a, b) => a.documentTypeDisplay.compareTo(b.documentTypeDisplay));
  return list;
}
