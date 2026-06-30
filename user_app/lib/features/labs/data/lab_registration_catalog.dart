/// Categories for lab registration test selection.
enum LabRegistrationCategory {
  bloodTests('Blood Tests', 'blood'),
  urineTests('Urine Tests', 'urine'),
  stoolTests('Stool Tests', 'stool'),
  diabetesTests('Diabetes Tests', 'diabetes'),
  thyroidTests('Thyroid Tests', 'thyroid'),
  liverFunctionTests('Liver Function Test (LFT)', 'lft'),
  kidneyFunctionTests('Kidney Function Test (KFT)', 'kft'),
  lipidProfile('Lipid Profile', 'lipid'),
  vitaminTests('Vitamin Tests', 'vitamin'),
  hormoneTests('Hormone Tests', 'hormone'),
  allergyTests('Allergy Tests', 'allergy'),
  cardiacTests('Cardiac Tests', 'cardiac'),
  pregnancyTests('Pregnancy Tests', 'pregnancy'),
  cancerMarkerTests('Cancer Marker Tests', 'cancer'),
  covid19Tests('COVID-19 Tests', 'covid'),
  fullBodyCheckups('Full Body Checkup Packages', 'checkup'),
  other('Other Diagnostic Tests', 'other');

  const LabRegistrationCategory(this.label, this.id);
  final String label;
  final String id;
}

class LabRegistrationTestTemplate {
  const LabRegistrationTestTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultDescription,
    this.defaultPreparation,
    this.defaultReportTime = '24 hours',
    this.defaultPrice = 499,
  });

  final String id;
  final String name;
  final LabRegistrationCategory category;
  final String defaultDescription;
  final String? defaultPreparation;
  final String defaultReportTime;
  final int defaultPrice;
}

/// Predefined diagnostic tests labs can select during registration.
class LabRegistrationCatalog {
  LabRegistrationCatalog._();

  static const List<LabRegistrationCategory> categories =
      LabRegistrationCategory.values;

  static const List<LabRegistrationTestTemplate> templates = [
    LabRegistrationTestTemplate(
      id: 'cbc',
      name: 'Complete Blood Count (CBC)',
      category: LabRegistrationCategory.bloodTests,
      defaultDescription: 'Measures RBC, WBC, platelets, and hemoglobin.',
      defaultPreparation: 'No fasting required.',
      defaultPrice: 399,
      defaultReportTime: '6–12 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'blood-group',
      name: 'Blood Group & Rh Typing',
      category: LabRegistrationCategory.bloodTests,
      defaultDescription: 'Determines ABO blood group and Rh factor.',
      defaultPrice: 149,
      defaultReportTime: '4–6 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'esr',
      name: 'ESR',
      category: LabRegistrationCategory.bloodTests,
      defaultDescription: 'Inflammation screening test.',
      defaultPrice: 199,
    ),
    LabRegistrationTestTemplate(
      id: 'urine-routine',
      name: 'Urine Routine & Microscopy',
      category: LabRegistrationCategory.urineTests,
      defaultDescription: 'Screens infection, protein, and sugar in urine.',
      defaultPreparation: 'Mid-stream clean-catch sample.',
      defaultPrice: 199,
    ),
    LabRegistrationTestTemplate(
      id: 'urine-culture',
      name: 'Urine Culture & Sensitivity',
      category: LabRegistrationCategory.urineTests,
      defaultDescription: 'Identifies bacterial infection and antibiotics.',
      defaultPrice: 699,
      defaultReportTime: '48–72 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'stool-routine',
      name: 'Stool Routine & Occult Blood',
      category: LabRegistrationCategory.stoolTests,
      defaultDescription: 'Digestive health and hidden blood screening.',
      defaultPrice: 349,
    ),
    LabRegistrationTestTemplate(
      id: 'fbs',
      name: 'Fasting Blood Sugar (FBS)',
      category: LabRegistrationCategory.diabetesTests,
      defaultDescription: 'Blood glucose after overnight fasting.',
      defaultPreparation: 'Fasting 8–12 hours.',
      defaultPrice: 99,
      defaultReportTime: '4–6 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'hba1c',
      name: 'HbA1c',
      category: LabRegistrationCategory.diabetesTests,
      defaultDescription: '3-month average blood sugar indicator.',
      defaultPrice: 499,
    ),
    LabRegistrationTestTemplate(
      id: 'thyroid-profile',
      name: 'Thyroid Profile (T3, T4, TSH)',
      category: LabRegistrationCategory.thyroidTests,
      defaultDescription: 'Comprehensive thyroid hormone panel.',
      defaultPrice: 599,
    ),
    LabRegistrationTestTemplate(
      id: 'tsh',
      name: 'TSH',
      category: LabRegistrationCategory.thyroidTests,
      defaultDescription: 'Primary thyroid disorder screening.',
      defaultPrice: 299,
    ),
    LabRegistrationTestTemplate(
      id: 'lft-basic',
      name: 'Liver Function Test (LFT)',
      category: LabRegistrationCategory.liverFunctionTests,
      defaultDescription: 'SGOT, SGPT, bilirubin, and alkaline phosphatase.',
      defaultPreparation: 'Fasting 8–10 hours recommended.',
      defaultPrice: 599,
    ),
    LabRegistrationTestTemplate(
      id: 'kft-basic',
      name: 'Kidney Function Test (KFT)',
      category: LabRegistrationCategory.kidneyFunctionTests,
      defaultDescription: 'Urea, creatinine, and uric acid levels.',
      defaultPrice: 499,
    ),
    LabRegistrationTestTemplate(
      id: 'lipid-basic',
      name: 'Lipid Profile',
      category: LabRegistrationCategory.lipidProfile,
      defaultDescription: 'Cholesterol, HDL, LDL, and triglycerides.',
      defaultPreparation: 'Fasting 10–12 hours required.',
      defaultPrice: 499,
    ),
    LabRegistrationTestTemplate(
      id: 'vitamin-d',
      name: 'Vitamin D (25-OH)',
      category: LabRegistrationCategory.vitaminTests,
      defaultDescription: 'Vitamin D deficiency screening.',
      defaultPrice: 1299,
      defaultReportTime: '24–48 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'vitamin-b12',
      name: 'Vitamin B12',
      category: LabRegistrationCategory.vitaminTests,
      defaultDescription: 'B12 deficiency and anemia screening.',
      defaultPrice: 899,
    ),
    LabRegistrationTestTemplate(
      id: 'testosterone',
      name: 'Testosterone Total',
      category: LabRegistrationCategory.hormoneTests,
      defaultDescription: 'Male hormone level evaluation.',
      defaultPreparation: 'Morning sample preferred.',
      defaultPrice: 699,
    ),
    LabRegistrationTestTemplate(
      id: 'ige-total',
      name: 'Total IgE',
      category: LabRegistrationCategory.allergyTests,
      defaultDescription: 'General allergy screening.',
      defaultPrice: 699,
    ),
    LabRegistrationTestTemplate(
      id: 'troponin',
      name: 'Troponin I',
      category: LabRegistrationCategory.cardiacTests,
      defaultDescription: 'Cardiac injury marker for heart attack.',
      defaultPrice: 999,
      defaultReportTime: '6–12 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'ecg',
      name: 'ECG (Electrocardiogram)',
      category: LabRegistrationCategory.cardiacTests,
      defaultDescription: 'Heart rhythm and electrical activity test.',
      defaultPrice: 299,
      defaultReportTime: '2–4 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'beta-hcg',
      name: 'Beta HCG (Pregnancy Test)',
      category: LabRegistrationCategory.pregnancyTests,
      defaultDescription: 'Confirms pregnancy via blood test.',
      defaultPrice: 499,
      defaultReportTime: '6–12 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'psa',
      name: 'PSA (Prostate Specific Antigen)',
      category: LabRegistrationCategory.cancerMarkerTests,
      defaultDescription: 'Prostate cancer screening marker.',
      defaultPrice: 799,
    ),
    LabRegistrationTestTemplate(
      id: 'ca-125',
      name: 'CA-125',
      category: LabRegistrationCategory.cancerMarkerTests,
      defaultDescription: 'Ovarian cancer marker screening.',
      defaultPrice: 1299,
    ),
    LabRegistrationTestTemplate(
      id: 'rt-pcr',
      name: 'COVID-19 RT-PCR',
      category: LabRegistrationCategory.covid19Tests,
      defaultDescription: 'Molecular test for active COVID-19 infection.',
      defaultPrice: 499,
    ),
    LabRegistrationTestTemplate(
      id: 'covid-antigen',
      name: 'COVID-19 Rapid Antigen',
      category: LabRegistrationCategory.covid19Tests,
      defaultDescription: 'Quick COVID screening test.',
      defaultPrice: 299,
      defaultReportTime: '2–4 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'basic-checkup',
      name: 'Basic Health Checkup',
      category: LabRegistrationCategory.fullBodyCheckups,
      defaultDescription: 'CBC, LFT, KFT, lipid profile, FBS, urine routine.',
      defaultPreparation: 'Fasting 10–12 hours required.',
      defaultPrice: 1999,
    ),
    LabRegistrationTestTemplate(
      id: 'comprehensive-checkup',
      name: 'Comprehensive Full Body Checkup',
      category: LabRegistrationCategory.fullBodyCheckups,
      defaultDescription: '60+ parameters including thyroid and vitamins.',
      defaultPreparation: 'Fasting 10–12 hours required.',
      defaultPrice: 4999,
      defaultReportTime: '48 hours',
    ),
    LabRegistrationTestTemplate(
      id: 'crp',
      name: 'C-Reactive Protein (CRP)',
      category: LabRegistrationCategory.other,
      defaultDescription: 'Inflammation and infection severity marker.',
      defaultPrice: 499,
    ),
    LabRegistrationTestTemplate(
      id: 'dengue-ns1',
      name: 'Dengue NS1 Antigen',
      category: LabRegistrationCategory.other,
      defaultDescription: 'Early dengue fever detection.',
      defaultPrice: 599,
    ),
  ];

  static List<LabRegistrationTestTemplate> byCategory(
    LabRegistrationCategory category,
  ) {
    return templates.where((t) => t.category == category).toList();
  }

  static LabRegistrationTestTemplate? findById(String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }
}
