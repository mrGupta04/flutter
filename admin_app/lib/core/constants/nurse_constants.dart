/// Nurse home-visit onboarding document types.
enum NurseDocumentType {
  nursingLicense('nursing_license', 'Nursing License / Registration'),
  degreeCertificate('degree_certificate', 'Degree / Qualification Certificate'),
  aadhaarCard('aadhaar_card', 'Aadhaar Card'),
  cancelledCheque('cancelled_cheque', 'Cancelled Cheque');

  const NurseDocumentType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// Total steps in nurse onboarding wizard (home visit only).
const totalNurseRegistrationSteps = 7;
