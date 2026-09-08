/// Standard ambulance vehicle types (matches patient search filters).
const ambulanceVehicleTypes = [
  'Basic Ambulance',
  'Basic Life Support',
  'Advanced Life Support',
  'ICU Ambulance',
  'Cardiac Ambulance',
  'Trauma Ambulance',
  'Neonatal Ambulance',
  'Pediatric Ambulance',
  'Isolation Ambulance',
  'Bariatric Ambulance',
  'Patient Transport',
  'First Responder / Bike Ambulance',
  'Air Ambulance',
  'Mortuary Van',
  'Event Medical Ambulance',
];

const ambulanceVehicleStatuses = [
  'AVAILABLE',
  'BUSY',
  'OFFLINE',
  'MAINTENANCE',
  'EMERGENCY_ONLY',
];

const ambulanceDriverStatuses = [
  'AVAILABLE',
  'ON_TRIP',
  'OFFLINE',
  'ON_BREAK',
  'SUSPENDED',
];

/// Service-level document types for upload.
enum AmbulanceServiceDocumentType {
  serviceLicense('serviceLicense', 'Ambulance Service License'),
  companyRegistration('companyRegistration', 'Company Registration Certificate'),
  gstCertificate('gstCertificate', 'GST Certificate'),
  fleetInsurance('fleetInsurance', 'Fleet Insurance Policy'),
  cancelledCheque('cancelledCheque', 'Cancelled Cheque');

  const AmbulanceServiceDocumentType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// Per-vehicle document types.
enum AmbulanceVehicleDocumentType {
  rcBook('rcBook', 'RC Book / Registration Certificate'),
  insurance('insurance', 'Vehicle Insurance'),
  fitnessCertificate('fitnessCertificate', 'Fitness Certificate'),
  pollutionCertificate('pollutionCertificate', 'Pollution Certificate'),
  photoFront('photoFront', 'Vehicle Photo (Front)'),
  photoBack('photoBack', 'Vehicle Photo (Back)'),
  photoInterior('photoInterior', 'Vehicle Photo (Interior)');

  const AmbulanceVehicleDocumentType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// Per-driver document types.
enum AmbulanceDriverDocumentType {
  governmentId('governmentId', 'Government ID (Aadhaar/PAN)'),
  drivingLicense('drivingLicense', 'Driving License'),
  emtCertificate('emtCertificate', 'EMT / Paramedic Certificate'),
  photo('photo', 'Driver Photo');

  const AmbulanceDriverDocumentType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// Total steps in ambulance onboarding wizard.
const totalAmbulanceRegistrationSteps = 7;
