import '../../../core/constants/karnataka_places.dart';
import '../../../shared/widgets/searchable_filter_dropdown.dart';

export '../../../data/models/ambulance_vehicle_types.dart'
    show ambulanceVehicleTypeFilters;
export '../../../core/constants/karnataka_places.dart'
    show karnatakaPlaceMatchesQuery;

/// Quick city chips for listing screens (Karnataka metros first).
const popularCareCities = [
  'Bengaluru',
  'Mysuru',
  'Mangaluru',
  'Hubballi',
  'Kalaburagi',
  'Belagavi',
  'Mumbai',
  'Delhi',
  'Hyderabad',
  'Chennai',
  'Pune',
  'Kolkata',
];

const otherMarketplaceCities = [
  'Mumbai',
  'Delhi',
  'Hyderabad',
  'Chennai',
  'Pune',
  'Kolkata',
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
  'Vadodara',
  'Patna',
  'Guwahati',
  'Varanasi',
  'Dehradun',
  'Ranchi',
  'Raipur',
  'Bhubaneswar',
  'Agra',
  'Ludhiana',
];

/// Cities available in doctor/nurse search. Karnataka districts and towns first.
final List<String> doctorSearchCities = [
  ...karnatakaSearchPlaces,
  ...otherMarketplaceCities,
];

/// Grouped city picker: every KA district, then towns, then other metros.
final List<SearchableOptionSection> careCityPickerSections = [
  const SearchableOptionSection(
    title: 'Karnataka districts',
    options: karnatakaDistricts,
  ),
  SearchableOptionSection(
    title: 'Cities & towns',
    options: karnatakaCanonicalTowns,
  ),
  const SearchableOptionSection(
    title: 'Other cities',
    options: otherMarketplaceCities,
  ),
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
