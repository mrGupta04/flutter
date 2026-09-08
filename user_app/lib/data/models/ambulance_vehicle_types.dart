class AmbulanceVehicleType {
  const AmbulanceVehicleType({
    required this.id,
    required this.label,
    this.shortLabel,
  });

  final String id;
  final String label;
  final String? shortLabel;

  String get chipLabel => shortLabel ?? label;
}

const ambulanceVehicleTypes = [
  AmbulanceVehicleType(id: 'basic', label: 'Basic Ambulance', shortLabel: 'Basic'),
  AmbulanceVehicleType(id: 'bls', label: 'Basic Life Support', shortLabel: 'BLS'),
  AmbulanceVehicleType(id: 'als', label: 'Advanced Life Support', shortLabel: 'ALS'),
  AmbulanceVehicleType(id: 'icu', label: 'ICU Ambulance', shortLabel: 'ICU'),
  AmbulanceVehicleType(id: 'cardiac', label: 'Cardiac Ambulance', shortLabel: 'Cardiac'),
  AmbulanceVehicleType(id: 'trauma', label: 'Trauma Ambulance', shortLabel: 'Trauma'),
  AmbulanceVehicleType(id: 'neonatal', label: 'Neonatal Ambulance', shortLabel: 'Neonatal'),
  AmbulanceVehicleType(id: 'pediatric', label: 'Pediatric Ambulance', shortLabel: 'Pediatric'),
  AmbulanceVehicleType(id: 'isolation', label: 'Isolation Ambulance', shortLabel: 'Isolation'),
  AmbulanceVehicleType(id: 'bariatric', label: 'Bariatric Ambulance', shortLabel: 'Bariatric'),
  AmbulanceVehicleType(
    id: 'patient_transport',
    label: 'Patient Transport Vehicle',
    shortLabel: 'Transport',
  ),
  AmbulanceVehicleType(
    id: 'first_responder',
    label: 'First Responder / Bike Ambulance',
    shortLabel: 'Bike',
  ),
  AmbulanceVehicleType(id: 'air', label: 'Air Ambulance', shortLabel: 'Air'),
  AmbulanceVehicleType(id: 'mortuary', label: 'Mortuary Van', shortLabel: 'Mortuary'),
  AmbulanceVehicleType(id: 'event', label: 'Event Medical Ambulance', shortLabel: 'Event'),
];

const ambulanceVehicleTypeFilters = [
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
