/// Shared city chips across care search screens.
const popularCareCities = [
  'Mumbai',
  'Delhi',
  'Bangalore',
  'Hyderabad',
  'Chennai',
  'Pune',
  'Kolkata',
];

/// Cities available in doctor search dropdown (searchable).
const doctorSearchCities = [
  ...popularCareCities,
  'Ahmedabad',
  'Jaipur',
  'Lucknow',
  'Chandigarh',
  'Coimbatore',
  'Indore',
  'Bhopal',
  'Nagpur',
  'Visakhapatnam',
  'Kochi',
  'Surat',
  'Noida',
  'Gurgaon',
  'Thiruvananthapuram',
  'Mysore',
  'Vadodara',
  'Patna',
  'Guwahati',
  'Varanasi',
  'Dehradun',
  'Ranchi',
  'Raipur',
  'Bhubaneswar',
  'Mangalore',
  'Agra',
  'Ludhiana',
];

/// Minimum years of experience filter values for doctor search.
const doctorMinExperienceOptions = <int?>[null, 1, 3, 5, 10, 15];

String doctorMinExperienceLabel(int? years) {
  if (years == null) return 'Any experience';
  return '$years+ years';
}

/// Nurse specialization filter chips (matches common registration values).
const nurseSpecializationFilters = [
  'Elder care',
  'Pediatric',
  'Post-op',
  'ICU',
  'Home care',
  'Geriatric',
];

/// Nurse gender filter options (matches registration).
const nurseGenderFilters = [
  'Male',
  'Female',
];

/// Ambulance vehicle type filter chips.
const ambulanceVehicleTypeFilters = [
  'Basic Life Support',
  'Advanced Life Support',
  'Patient Transport',
  'ICU Ambulance',
];

/// Blood group filter chips.
const bloodGroupFilters = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];
