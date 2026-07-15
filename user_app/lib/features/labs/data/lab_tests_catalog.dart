import 'models/lab_test_model.dart';

/// Static catalog of diagnostic tests grouped by category.
class LabTestsCatalog {
  LabTestsCatalog._();

  static const List<LabTestCategory> allCategories = LabTestCategory.values;

  static const List<LabTest> tests = [
    // Blood Tests
    LabTest(
      id: 'cbc',
      name: 'Complete Blood Count (CBC)',
      description:
          'Measures red cells, white cells, platelets, and hemoglobin levels.',
      priceInr: 399,
      originalPriceInr: 699,
      reportDeliveryTime: '6–12 hours',
      category: LabTestCategory.bloodTests,
      preparationInstructions: 'No fasting required.',
      includedTestsLabel: 'RBC, WBC, Platelets, Hb',
      parameterCount: 18,
      highlightText: 'Screens anemia, infection & blood health',
    ),
    LabTest(
      id: 'esr',
      name: 'ESR (Erythrocyte Sedimentation Rate)',
      description: 'Detects inflammation in the body.',
      priceInr: 199,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.bloodTests,
    ),
    LabTest(
      id: 'blood-group',
      name: 'Blood Group & Rh Typing',
      description: 'Determines your ABO blood group and Rh factor.',
      priceInr: 149,
      reportDeliveryTime: '4–6 hours',
      category: LabTestCategory.bloodTests,
    ),
    LabTest(
      id: 'iron-studies',
      name: 'Iron Studies',
      description: 'Serum iron, TIBC, and ferritin for anemia evaluation.',
      priceInr: 899,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.bloodTests,
      preparationInstructions: 'Fasting 8–10 hours recommended.',
    ),

    // Urine Tests
    LabTest(
      id: 'urine-routine',
      name: 'Urine Routine & Microscopy',
      description: 'Screens for infection, protein, sugar, and crystals.',
      priceInr: 199,
      reportDeliveryTime: '6–12 hours',
      category: LabTestCategory.urineTests,
      preparationInstructions: 'Mid-stream clean-catch sample preferred.',
    ),
    LabTest(
      id: 'urine-culture',
      name: 'Urine Culture & Sensitivity',
      description: 'Identifies bacterial infection and suitable antibiotics.',
      priceInr: 699,
      reportDeliveryTime: '48–72 hours',
      category: LabTestCategory.urineTests,
    ),
    LabTest(
      id: 'urine-microalbumin',
      name: 'Urine Microalbumin',
      description: 'Early marker for kidney damage, especially in diabetes.',
      priceInr: 549,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.urineTests,
      preparationInstructions: 'Avoid strenuous exercise 24 hours before.',
    ),

    // Thyroid Tests
    LabTest(
      id: 'thyroid-profile',
      name: 'Thyroid Care',
      description: 'Assesses thyroid function & metabolism health',
      priceInr: 649,
      originalPriceInr: 1199,
      reportDeliveryTime: '23 hours',
      category: LabTestCategory.thyroidTests,
      includedTestsLabel: 'TSH, T3, T4',
      parameterCount: 31,
      highlightText: 'Assesses thyroid function & metabolism health',
    ),
    LabTest(
      id: 'tsh',
      name: 'TSH (Thyroid Stimulating Hormone)',
      description: 'Primary screening test for thyroid disorders.',
      priceInr: 299,
      originalPriceInr: 549,
      reportDeliveryTime: '12 hours',
      category: LabTestCategory.thyroidTests,
      includedTestsLabel: 'TSH',
      parameterCount: 1,
      highlightText: 'Primary screening for thyroid disorders',
    ),
    LabTest(
      id: 'anti-tpo',
      name: 'Anti-TPO Antibodies',
      description: 'Helps diagnose autoimmune thyroid disease.',
      priceInr: 799,
      originalPriceInr: 1299,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.thyroidTests,
      includedTestsLabel: 'Anti-TPO',
      parameterCount: 1,
      highlightText: 'Screens autoimmune thyroid conditions',
    ),

    // Diabetes Tests
    LabTest(
      id: 'fbs',
      name: 'Fasting Blood Sugar (FBS)',
      description: 'Measures blood glucose after overnight fasting.',
      priceInr: 99,
      reportDeliveryTime: '4–6 hours',
      category: LabTestCategory.diabetesTests,
      preparationInstructions: 'Fasting 8–12 hours required.',
    ),
    LabTest(
      id: 'ppbs',
      name: 'Post Prandial Blood Sugar (PPBS)',
      description: 'Blood sugar measured 2 hours after a meal.',
      priceInr: 99,
      reportDeliveryTime: '4–6 hours',
      category: LabTestCategory.diabetesTests,
      preparationInstructions: 'Eat a standard meal 2 hours before sample.',
    ),
    LabTest(
      id: 'hba1c',
      name: 'HbA1c (Glycated Hemoglobin)',
      description: '3-month average blood sugar control indicator.',
      priceInr: 499,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.diabetesTests,
    ),
    LabTest(
      id: 'glucose-tolerance',
      name: 'Glucose Tolerance Test (GTT)',
      description: 'Diagnoses gestational and type 2 diabetes.',
      priceInr: 699,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.diabetesTests,
      preparationInstructions: 'Fasting 8–12 hours; follow lab instructions.',
      onsiteAvailable: true,
      homeVisitAvailable: false,
    ),

    // Liver Function Tests
    LabTest(
      id: 'lft-basic',
      name: 'Liver Function Test (LFT) – Basic',
      description: 'SGOT, SGPT, bilirubin, and alkaline phosphatase.',
      priceInr: 599,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.liverFunctionTests,
      preparationInstructions: 'Fasting 8–10 hours recommended.',
    ),
    LabTest(
      id: 'lft-advanced',
      name: 'Liver Function Test (LFT) – Advanced',
      description: 'Extended panel including GGT, albumin, and proteins.',
      priceInr: 999,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.liverFunctionTests,
      preparationInstructions: 'Fasting 8–10 hours recommended.',
    ),

    // Kidney Function Tests
    LabTest(
      id: 'kft-basic',
      name: 'Kidney Function Test (KFT) – Basic',
      description: 'Urea, creatinine, and uric acid levels.',
      priceInr: 499,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.kidneyFunctionTests,
    ),
    LabTest(
      id: 'kft-advanced',
      name: 'Kidney Function Test (KFT) – Advanced',
      description: 'Includes electrolytes, calcium, and phosphorus.',
      priceInr: 899,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.kidneyFunctionTests,
    ),

    // Lipid Profile
    LabTest(
      id: 'lipid-basic',
      name: 'Lipid Profile – Basic',
      description: 'Total cholesterol, HDL, LDL, and triglycerides.',
      priceInr: 499,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.lipidProfile,
      preparationInstructions: 'Fasting 10–12 hours required.',
    ),
    LabTest(
      id: 'lipid-advanced',
      name: 'Lipid Profile – Advanced',
      description: 'Includes VLDL, LDL/HDL ratio, and non-HDL cholesterol.',
      priceInr: 799,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.lipidProfile,
      preparationInstructions: 'Fasting 10–12 hours required.',
    ),

    // Vitamin Tests
    LabTest(
      id: 'vitamin-d',
      name: 'Vitamin D (25-OH)',
      description: 'Assesses vitamin D deficiency or excess.',
      priceInr: 1299,
      reportDeliveryTime: '24–48 hours',
      category: LabTestCategory.vitaminTests,
    ),
    LabTest(
      id: 'vitamin-b12',
      name: 'Vitamin B12',
      description: 'Screens for B12 deficiency causing fatigue and anemia.',
      priceInr: 899,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.vitaminTests,
    ),
    LabTest(
      id: 'vitamin-panel',
      name: 'Vitamin Panel (D, B12, Folate)',
      description: 'Combined vitamin deficiency screening.',
      priceInr: 2199,
      reportDeliveryTime: '48 hours',
      category: LabTestCategory.vitaminTests,
    ),

    // Hormone Tests
    LabTest(
      id: 'testosterone',
      name: 'Testosterone Total',
      description: 'Evaluates male hormone levels and related symptoms.',
      priceInr: 699,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.hormoneTests,
      preparationInstructions: 'Sample ideally collected in the morning.',
    ),
    LabTest(
      id: 'progesterone',
      name: 'Progesterone',
      description: 'Assesses ovulation and pregnancy-related hormone levels.',
      priceInr: 799,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.hormoneTests,
    ),
    LabTest(
      id: 'cortisol',
      name: 'Cortisol (Morning)',
      description: 'Screens adrenal function and stress hormone levels.',
      priceInr: 899,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.hormoneTests,
      preparationInstructions: 'Morning sample (7–9 AM) preferred.',
    ),

    // Allergy Tests
    LabTest(
      id: 'ige-total',
      name: 'Total IgE',
      description: 'General allergy screening blood test.',
      priceInr: 699,
      reportDeliveryTime: '24–48 hours',
      category: LabTestCategory.allergyTests,
    ),
    LabTest(
      id: 'food-allergy-panel',
      name: 'Food Allergy Panel (20 allergens)',
      description: 'Screens common food allergens including nuts and dairy.',
      priceInr: 3499,
      reportDeliveryTime: '3–5 days',
      category: LabTestCategory.allergyTests,
    ),
    LabTest(
      id: 'inhalant-allergy',
      name: 'Inhalant Allergy Panel',
      description: 'Dust, pollen, mold, and pet dander sensitivity.',
      priceInr: 2999,
      reportDeliveryTime: '3–5 days',
      category: LabTestCategory.allergyTests,
    ),

    // COVID-19 Tests
    LabTest(
      id: 'rt-pcr',
      name: 'COVID-19 RT-PCR',
      description: 'Gold-standard molecular test for active infection.',
      priceInr: 499,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.covid19Tests,
    ),
    LabTest(
      id: 'rapid-antigen',
      name: 'COVID-19 Rapid Antigen',
      description: 'Quick screening for symptomatic individuals.',
      priceInr: 299,
      reportDeliveryTime: '2–4 hours',
      category: LabTestCategory.covid19Tests,
    ),
    LabTest(
      id: 'covid-antibody',
      name: 'COVID-19 Antibody (IgG)',
      description: 'Detects past infection or post-vaccination antibodies.',
      priceInr: 599,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.covid19Tests,
    ),

    // Full Body Checkups
    LabTest(
      id: 'basic-checkup',
      name: 'Basic Health Checkup',
      description: 'CBC, LFT, KFT, lipid profile, FBS, and urine routine.',
      priceInr: 1999,
      originalPriceInr: 3499,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.fullBodyCheckups,
      preparationInstructions: 'Fasting 10–12 hours required.',
      includedTestsLabel: 'CBC, LFT, KFT, Lipid, FBS',
      parameterCount: 45,
      highlightText: 'Everyday essentials for routine health monitoring',
    ),
    LabTest(
      id: 'comprehensive-checkup',
      name: 'Comprehensive Full Body Checkup',
      description:
          '60+ parameters including thyroid, vitamins, and organ panels.',
      priceInr: 4999,
      originalPriceInr: 7999,
      reportDeliveryTime: '48 hours',
      category: LabTestCategory.fullBodyCheckups,
      preparationInstructions: 'Fasting 10–12 hours; carry previous reports.',
      includedTestsLabel: 'Thyroid, Vitamins, Organ panels',
      parameterCount: 65,
      highlightText: 'Complete metabolic & organ health assessment',
    ),
    LabTest(
      id: 'senior-checkup',
      name: 'Senior Citizen Health Package',
      description: 'Tailored panel for adults 60+ with cardiac and bone markers.',
      priceInr: 3999,
      originalPriceInr: 5999,
      reportDeliveryTime: '48 hours',
      category: LabTestCategory.fullBodyCheckups,
      preparationInstructions: 'Fasting 10–12 hours required.',
      includedTestsLabel: 'Cardiac, Bone & Metabolic',
      parameterCount: 55,
      highlightText: 'Age-focused screening for adults 60+',
    ),
    LabTest(
      id: 'womens-checkup',
      name: "Women's Wellness Package",
      description: 'Hormones, iron, thyroid, and vitamin screening for women.',
      priceInr: 3499,
      originalPriceInr: 5499,
      reportDeliveryTime: '48 hours',
      category: LabTestCategory.fullBodyCheckups,
      preparationInstructions: 'Fasting 8–10 hours recommended.',
      includedTestsLabel: 'Hormones, Iron, Thyroid, Vitamins',
      parameterCount: 48,
      highlightText: 'Wellness screening designed for women',
    ),

    // Other Investigations
    LabTest(
      id: 'crp',
      name: 'C-Reactive Protein (CRP)',
      description: 'Marker of inflammation and infection severity.',
      priceInr: 499,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.other,
    ),
    LabTest(
      id: 'psa',
      name: 'PSA (Prostate Specific Antigen)',
      description: 'Prostate health screening for men over 45.',
      priceInr: 799,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.other,
      preparationInstructions: 'Avoid cycling and vigorous exercise 48 hrs prior.',
    ),
    LabTest(
      id: 'stool-routine',
      name: 'Stool Routine & Occult Blood',
      description: 'Screens digestive health and hidden blood in stool.',
      priceInr: 349,
      reportDeliveryTime: '24 hours',
      category: LabTestCategory.other,
      homeVisitAvailable: false,
      onsiteAvailable: true,
    ),
    LabTest(
      id: 'dengue-ns1',
      name: 'Dengue NS1 Antigen',
      description: 'Early detection of dengue fever during acute phase.',
      priceInr: 599,
      reportDeliveryTime: '12–24 hours',
      category: LabTestCategory.other,
    ),
  ];

  static List<LabTest> filter({
    String? query,
    LabTestCategory? category,
  }) {
    return tests.where((test) {
      if (category != null && test.category != category) return false;
      if (query != null && query.isNotEmpty && !test.matchesQuery(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  static Map<LabTestCategory, List<LabTest>> groupedByCategory(
    List<LabTest> filtered,
  ) {
    final map = <LabTestCategory, List<LabTest>>{};
    for (final test in filtered) {
      map.putIfAbsent(test.category, () => []).add(test);
    }
    return map;
  }

  static LabTest? byId(String id) {
    for (final test in tests) {
      if (test.id == id) return test;
    }
    return null;
  }

  static List<LabTest> byIds(List<String> ids) {
    return ids.map(byId).whereType<LabTest>().toList();
  }
}
