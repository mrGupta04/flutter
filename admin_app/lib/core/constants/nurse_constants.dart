/// Nurse home-visit onboarding document types.
enum NurseDocumentType {
  nursingLicense('nursing_license', 'Nursing License / Registration'),
  degreeCertificate('degree_certificate', 'Degree / Qualification Certificate'),
  aadhaarCard('aadhaar_card', 'Aadhaar Card'),
  panCard('pan_card', 'PAN Card'),
  policeVerification('police_verification', 'Police Verification Certificate'),
  experienceCertificate('experience_certificate', 'Experience Certificate'),
  signature('signature', 'Digital Signature'),
  cancelledCheque('cancelled_cheque', 'Cancelled Cheque');

  const NurseDocumentType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// Gender options for nurse registration.
const nurseGenders = [
  'Male',
  'Female',
];

/// Structured qualification options (INC / NRTS style).
const nurseQualifications = [
  'ANM',
  'GNM',
  'B.Sc Nursing',
  'Post Basic B.Sc Nursing',
  'M.Sc Nursing',
  'Other',
];

/// Clinical skills / services offered on home visits.
const nurseClinicalSkills = [
  'Vitals monitoring',
  'Medication administration',
  'Wound dressing',
  'IV / IM injection',
  'Catheter care',
  'Ryles tube care',
  'Elderly care',
  'Post-operative care',
  'Palliative care',
  'Pediatric care',
  'Geriatric care',
  'Blood sample collection',
];

/// How far a nurse is willing to travel for home visits (km).
const nurseServiceRadiusOptions = [5, 10, 15, 20, 25];

/// Total steps in nurse onboarding wizard (home visit only).
const totalNurseRegistrationSteps = 7;

/// Documents required before admin review (step 4).
const requiredNurseDocuments = [
  NurseDocumentType.nursingLicense,
  NurseDocumentType.degreeCertificate,
  NurseDocumentType.aadhaarCard,
  NurseDocumentType.panCard,
];
