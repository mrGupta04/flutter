const List<String> kBloodGroups = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

const List<String> kBloodGroupsExtended = [
  ...kBloodGroups,
  'Bombay',
  'Rare',
];

const List<Map<String, String>> kBloodComponents = [
  {'id': 'whole_blood', 'name': 'Whole Blood'},
  {'id': 'packed_rbc', 'name': 'Packed Red Blood Cells (PRBC)'},
  {'id': 'platelets', 'name': 'Platelets'},
  {'id': 'plasma', 'name': 'Fresh Frozen Plasma (FFP)'},
  {'id': 'cryoprecipitate', 'name': 'Cryoprecipitate'},
];

const List<int> kBloodSearchRadiiKm = [5, 10, 25, 50];

const List<Map<String, String>> kBloodBankTypes = [
  {'id': 'government', 'name': 'Government'},
  {'id': 'private', 'name': 'Private'},
  {'id': 'hospital', 'name': 'Hospital Blood Bank'},
  {'id': 'standalone', 'name': 'Standalone Blood Centre'},
];

String bloodComponentLabel(String? id) {
  for (final c in kBloodComponents) {
    if (c['id'] == id) return c['name'] ?? id ?? 'Blood component';
  }
  return id ?? 'Blood component';
}

const List<String> kBloodBankFacilities = [
  'Blood Storage',
  'Blood Component Separation',
  'Platelet Availability',
  'Plasma Availability',
  'Packed RBC',
  'Cryoprecipitate',
  'Rare Blood Groups',
  'Home Delivery',
  'Blood Donation Camp',
  'Voluntary Blood Donation Registration',
  'Emergency Blood Supply',
  'Walk-in Collection',
  'Online Booking',
];
