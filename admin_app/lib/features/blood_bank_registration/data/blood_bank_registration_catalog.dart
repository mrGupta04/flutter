const List<String> kBloodGroups = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Bombay', 'Rare',
];

const List<Map<String, String>> kBloodComponents = [
  {'id': 'whole_blood', 'name': 'Whole Blood'},
  {'id': 'packed_rbc', 'name': 'Packed RBC'},
  {'id': 'platelets', 'name': 'Platelets'},
  {'id': 'plasma', 'name': 'Plasma'},
  {'id': 'cryoprecipitate', 'name': 'Cryoprecipitate'},
];

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

const List<String> kWorkingDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

int defaultComponentPrice(String componentId) {
  switch (componentId) {
    case 'whole_blood':
      return 1200;
    case 'packed_rbc':
      return 1500;
    case 'platelets':
      return 11000;
    case 'plasma':
      return 400;
    case 'cryoprecipitate':
      return 250;
    default:
      return 1000;
  }
}
