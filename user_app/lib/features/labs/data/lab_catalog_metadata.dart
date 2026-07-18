import 'package:flutter/material.dart';

import 'lab_tests_catalog.dart';
import 'models/lab_test_model.dart';

enum LabBrowseGroupType { package, healthRisk, healthCondition, bodyOrgan }

class LabBrowseGroup {
  const LabBrowseGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.testIds,
    this.icon = Icons.biotech_outlined,
    this.imageUrl,
    this.subtitle,
  });

  final String id;
  final String name;
  final LabBrowseGroupType type;
  final List<String> testIds;
  final IconData icon;
  final String? imageUrl;
  final String? subtitle;

  List<LabTest> get tests => LabTestsCatalog.byIds(testIds);

  int get testCount => tests.length;

  int get startingPriceInr {
    final prices = tests.map((t) => t.effectivePrice).toList();
    if (prices.isEmpty) return 0;
    return prices.reduce((a, b) => a < b ? a : b);
  }
}

class LabHealthPackage {
  const LabHealthPackage({
    required this.id,
    required this.name,
    required this.testIds,
    required this.originalPriceInr,
    required this.discountedPriceInr,
    required this.reportTime,
    this.imageUrl,
    this.badge,
    this.subtitle,
    this.description,
    this.parameterCount,
  });

  final String id;
  final String name;
  final List<String> testIds;
  final int originalPriceInr;
  final int discountedPriceInr;
  final String reportTime;
  final String? imageUrl;
  final String? badge;
  final String? subtitle;
  final String? description;
  final int? parameterCount;

  int get testCount => parameterCount ?? testIds.length;

  String get testsCountLabel {
    final count = testCount;
    return '$count ${count == 1 ? 'TEST' : 'TESTS'}';
  }

  String get reportTimeCompact {
    final digits = RegExp(r'(\d+)').allMatches(reportTime).toList();
    if (digits.isEmpty) return reportTime.toUpperCase();
    final hours = digits.last.group(1)!;
    final lower = reportTime.toLowerCase();
    if (lower.contains('day')) return '$hours DAYS';
    return '$hours HRS';
  }

  int get discountPercent =>
      (((originalPriceInr - discountedPriceInr) / originalPriceInr) * 100)
          .round();

  List<LabTest> get tests => LabTestsCatalog.byIds(testIds);
}

/// Static browse metadata for packages, risks, conditions, and organs.
class LabCatalogMetadata {
  LabCatalogMetadata._();

  static const healthPackages = [
    LabHealthPackage(
      id: 'popular',
      name: 'Popular Health Pack',
      testIds: ['basic-checkup', 'comprehensive-checkup'],
      originalPriceInr: 6998,
      discountedPriceInr: 5499,
      reportTime: '24–48 hours',
      badge: 'POPULAR',
      subtitle: 'CBC, LFT, KFT, Lipid & more',
      description: 'Most booked checkup combo for everyday health tracking',
      parameterCount: 70,
    ),
    LabHealthPackage(
      id: 'full-body',
      name: 'Full Body Checkup',
      testIds: ['comprehensive-checkup'],
      originalPriceInr: 5999,
      discountedPriceInr: 4999,
      reportTime: '48 hours',
      subtitle: '60+ parameters',
      description: 'Complete organ panels, vitamins & metabolic markers',
      parameterCount: 60,
    ),
    LabHealthPackage(
      id: 'womens',
      name: "Women's Health",
      testIds: ['womens-checkup', 'thyroid-profile', 'vitamin-d'],
      originalPriceInr: 5597,
      discountedPriceInr: 4299,
      reportTime: '48 hours',
      subtitle: 'Hormones, Iron, Thyroid, Vit D',
      description: 'Tailored wellness screening designed for women',
      parameterCount: 45,
    ),
    LabHealthPackage(
      id: 'mens',
      name: "Men's Health",
      testIds: ['basic-checkup', 'testosterone', 'lipid-basic'],
      originalPriceInr: 3197,
      discountedPriceInr: 2599,
      reportTime: '24 hours',
      subtitle: 'Heart, Hormone & Metabolic',
      description: 'Core screening for fitness and heart health in men',
      parameterCount: 40,
    ),
    LabHealthPackage(
      id: 'senior',
      name: 'Senior Citizen',
      testIds: ['senior-checkup'],
      originalPriceInr: 4499,
      discountedPriceInr: 3999,
      reportTime: '48 hours',
      subtitle: 'Cardiac & Bone markers',
      description: 'Age-focused panel for adults 60 years and above',
      parameterCount: 55,
    ),
    LabHealthPackage(
      id: 'diabetes-pkg',
      name: 'Diabetes Care',
      testIds: ['fbs', 'ppbs', 'hba1c'],
      originalPriceInr: 697,
      discountedPriceInr: 549,
      reportTime: '12–24 hours',
      subtitle: 'FBS, PPBS, HbA1c',
      description: 'Monitors blood sugar control and diabetes risk',
      parameterCount: 3,
    ),
    LabHealthPackage(
      id: 'thyroid-pkg',
      name: 'Thyroid Care',
      testIds: ['thyroid-profile', 'tsh', 'anti-tpo'],
      originalPriceInr: 1697,
      discountedPriceInr: 649,
      reportTime: '24 hours',
      subtitle: 'TSH, T3, T4',
      description: 'Assesses thyroid function & metabolism health',
      parameterCount: 31,
    ),
    LabHealthPackage(
      id: 'heart-pkg',
      name: 'Heart Health',
      testIds: ['lipid-advanced', 'crp'],
      originalPriceInr: 1298,
      discountedPriceInr: 999,
      reportTime: '24 hours',
      subtitle: 'Lipid & CRP',
      description: 'Screens cholesterol and inflammation for heart risk',
      parameterCount: 9,
    ),
    LabHealthPackage(
      id: 'liver-pkg',
      name: 'Liver Function',
      testIds: ['lft-basic', 'lft-advanced'],
      originalPriceInr: 1598,
      discountedPriceInr: 1199,
      reportTime: '24 hours',
      subtitle: 'SGOT, SGPT, Bilirubin',
      description: 'Evaluates liver enzymes and overall liver health',
      parameterCount: 12,
    ),
    LabHealthPackage(
      id: 'kidney-pkg',
      name: 'Kidney Function',
      testIds: ['kft-basic', 'kft-advanced'],
      originalPriceInr: 1398,
      discountedPriceInr: 1099,
      reportTime: '24 hours',
      subtitle: 'Creatinine, Urea, eGFR',
      description: 'Checks kidney filtration and waste clearance',
      parameterCount: 10,
    ),
    LabHealthPackage(
      id: 'vitamin-pkg',
      name: 'Vitamin Care',
      testIds: ['vitamin-panel', 'vitamin-d', 'vitamin-b12'],
      originalPriceInr: 4397,
      discountedPriceInr: 3299,
      reportTime: '48 hours',
      subtitle: 'D, B12, Folate',
      description: 'Detects common vitamin deficiencies early',
      parameterCount: 5,
    ),
    LabHealthPackage(
      id: 'cancer-pkg',
      name: 'Cancer Screening',
      testIds: ['psa', 'crp'],
      originalPriceInr: 1298,
      discountedPriceInr: 999,
      reportTime: '24 hours',
      subtitle: 'PSA & Inflammation',
      description: 'Early screening markers for selected cancer risks',
      parameterCount: 2,
    ),
  ];

  static const healthRisks = [
    LabBrowseGroup(
      id: 'diabetes-risk',
      name: 'Diabetes Risk',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['fbs', 'ppbs', 'hba1c', 'glucose-tolerance'],
      icon: Icons.water_drop_rounded,
    ),
    LabBrowseGroup(
      id: 'heart-risk',
      name: 'Heart Disease Risk',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['lipid-basic', 'lipid-advanced', 'crp'],
      icon: Icons.favorite_rounded,
    ),
    LabBrowseGroup(
      id: 'kidney-risk',
      name: 'Kidney Disease Risk',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['kft-basic', 'kft-advanced', 'urine-microalbumin'],
      icon: Icons.filter_alt_rounded,
    ),
    LabBrowseGroup(
      id: 'liver-risk',
      name: 'Liver Disease Risk',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['lft-basic', 'lft-advanced'],
      icon: Icons.local_hospital_rounded,
    ),
    LabBrowseGroup(
      id: 'thyroid-risk',
      name: 'Thyroid Risk',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['thyroid-profile', 'tsh', 'anti-tpo'],
      icon: Icons.monitor_heart_rounded,
    ),
    LabBrowseGroup(
      id: 'vitamin-risk',
      name: 'Vitamin Deficiency',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['vitamin-d', 'vitamin-b12', 'vitamin-panel'],
      icon: Icons.wb_sunny_rounded,
    ),
    LabBrowseGroup(
      id: 'cancer-risk',
      name: 'Cancer Screening',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['psa', 'crp'],
      icon: Icons.health_and_safety_rounded,
    ),
    LabBrowseGroup(
      id: 'obesity-risk',
      name: 'Obesity Risk',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['lipid-basic', 'fbs', 'thyroid-profile'],
      icon: Icons.monitor_weight_rounded,
    ),
    LabBrowseGroup(
      id: 'hypertension-risk',
      name: 'Hypertension',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['lipid-basic', 'kft-basic', 'urine-routine'],
      icon: Icons.speed_rounded,
    ),
    LabBrowseGroup(
      id: 'cholesterol-risk',
      name: 'Cholesterol Risk',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['lipid-basic', 'lipid-advanced'],
      icon: Icons.opacity_rounded,
    ),
    LabBrowseGroup(
      id: 'bone-risk',
      name: 'Bone Health',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['vitamin-d', 'cbc'],
      icon: Icons.accessibility_new_rounded,
    ),
    LabBrowseGroup(
      id: 'hormonal-risk',
      name: 'Hormonal Disorders',
      type: LabBrowseGroupType.healthRisk,
      testIds: ['testosterone', 'progesterone', 'cortisol', 'thyroid-profile'],
      icon: Icons.science_rounded,
    ),
  ];

  static const healthConditions = [
    LabBrowseGroup(id: 'diabetes', name: 'Diabetes', type: LabBrowseGroupType.healthCondition, testIds: ['fbs', 'ppbs', 'hba1c'], icon: Icons.water_drop_rounded),
    LabBrowseGroup(id: 'fever', name: 'Fever', type: LabBrowseGroupType.healthCondition, testIds: ['cbc', 'crp'], icon: Icons.thermostat_rounded),
    LabBrowseGroup(id: 'dengue', name: 'Dengue', type: LabBrowseGroupType.healthCondition, testIds: ['dengue-ns1', 'cbc'], icon: Icons.bug_report_rounded),
    LabBrowseGroup(id: 'malaria', name: 'Malaria', type: LabBrowseGroupType.healthCondition, testIds: ['cbc'], icon: Icons.coronavirus_rounded),
    LabBrowseGroup(id: 'covid', name: 'COVID', type: LabBrowseGroupType.healthCondition, testIds: ['rt-pcr', 'rapid-antigen', 'covid-antibody'], icon: Icons.masks_rounded),
    LabBrowseGroup(id: 'pregnancy', name: 'Pregnancy', type: LabBrowseGroupType.healthCondition, testIds: ['progesterone', 'cbc'], icon: Icons.pregnant_woman_rounded),
    LabBrowseGroup(id: 'pcos', name: 'PCOS', type: LabBrowseGroupType.healthCondition, testIds: ['testosterone', 'progesterone', 'thyroid-profile'], icon: Icons.female_rounded),
    LabBrowseGroup(id: 'thyroid', name: 'Thyroid', type: LabBrowseGroupType.healthCondition, testIds: ['thyroid-profile', 'tsh'], icon: Icons.monitor_heart_rounded),
    LabBrowseGroup(id: 'cholesterol', name: 'Cholesterol', type: LabBrowseGroupType.healthCondition, testIds: ['lipid-basic', 'lipid-advanced'], icon: Icons.favorite_rounded),
    LabBrowseGroup(id: 'anemia', name: 'Anemia', type: LabBrowseGroupType.healthCondition, testIds: ['cbc', 'iron-studies'], icon: Icons.bloodtype_rounded),
    LabBrowseGroup(id: 'vitamin-d', name: 'Vitamin D Deficiency', type: LabBrowseGroupType.healthCondition, testIds: ['vitamin-d'], icon: Icons.wb_sunny_rounded),
    LabBrowseGroup(id: 'vitamin-b12', name: 'Vitamin B12', type: LabBrowseGroupType.healthCondition, testIds: ['vitamin-b12'], icon: Icons.bolt_rounded),
    LabBrowseGroup(id: 'arthritis', name: 'Arthritis', type: LabBrowseGroupType.healthCondition, testIds: ['crp', 'esr'], icon: Icons.accessibility_new_rounded),
    LabBrowseGroup(id: 'fatty-liver', name: 'Fatty Liver', type: LabBrowseGroupType.healthCondition, testIds: ['lft-basic', 'lft-advanced'], icon: Icons.local_hospital_rounded),
    LabBrowseGroup(id: 'kidney-disease', name: 'Kidney Disease', type: LabBrowseGroupType.healthCondition, testIds: ['kft-basic', 'kft-advanced'], icon: Icons.filter_alt_rounded),
    LabBrowseGroup(id: 'asthma', name: 'Asthma', type: LabBrowseGroupType.healthCondition, testIds: ['ige-total', 'inhalant-allergy'], icon: Icons.air_rounded),
    LabBrowseGroup(id: 'allergy', name: 'Allergy', type: LabBrowseGroupType.healthCondition, testIds: ['ige-total', 'food-allergy-panel'], icon: Icons.spa_rounded),
    LabBrowseGroup(id: 'hypertension', name: 'Hypertension', type: LabBrowseGroupType.healthCondition, testIds: ['lipid-basic', 'kft-basic'], icon: Icons.speed_rounded),
  ];

  static const bodyOrgans = [
    LabBrowseGroup(id: 'heart', name: 'Heart', type: LabBrowseGroupType.bodyOrgan, testIds: ['lipid-advanced', 'crp'], icon: Icons.favorite_rounded),
    LabBrowseGroup(id: 'liver', name: 'Liver', type: LabBrowseGroupType.bodyOrgan, testIds: ['lft-basic', 'lft-advanced'], icon: Icons.local_hospital_rounded),
    LabBrowseGroup(id: 'kidney', name: 'Kidney', type: LabBrowseGroupType.bodyOrgan, testIds: ['kft-basic', 'kft-advanced'], icon: Icons.filter_alt_rounded),
    LabBrowseGroup(id: 'brain', name: 'Brain', type: LabBrowseGroupType.bodyOrgan, testIds: ['vitamin-b12', 'thyroid-profile'], icon: Icons.psychology_rounded),
    LabBrowseGroup(id: 'lungs', name: 'Lungs', type: LabBrowseGroupType.bodyOrgan, testIds: ['inhalant-allergy', 'rt-pcr'], icon: Icons.air_rounded),
    LabBrowseGroup(id: 'stomach', name: 'Stomach', type: LabBrowseGroupType.bodyOrgan, testIds: ['stool-routine'], icon: Icons.restaurant_rounded),
    LabBrowseGroup(id: 'bones', name: 'Bones', type: LabBrowseGroupType.bodyOrgan, testIds: ['vitamin-d'], icon: Icons.accessibility_new_rounded),
    LabBrowseGroup(id: 'blood', name: 'Blood', type: LabBrowseGroupType.bodyOrgan, testIds: ['cbc', 'esr', 'blood-group'], icon: Icons.bloodtype_rounded),
    LabBrowseGroup(id: 'hormones', name: 'Hormones', type: LabBrowseGroupType.bodyOrgan, testIds: ['testosterone', 'progesterone', 'cortisol'], icon: Icons.science_rounded),
    LabBrowseGroup(id: 'thyroid-organ', name: 'Thyroid', type: LabBrowseGroupType.bodyOrgan, testIds: ['thyroid-profile', 'tsh'], icon: Icons.monitor_heart_rounded),
    LabBrowseGroup(id: 'eyes', name: 'Eyes', type: LabBrowseGroupType.bodyOrgan, testIds: ['vitamin-d', 'vitamin-b12'], icon: Icons.visibility_rounded),
    LabBrowseGroup(id: 'skin', name: 'Skin', type: LabBrowseGroupType.bodyOrgan, testIds: ['food-allergy-panel', 'ige-total'], icon: Icons.face_rounded),
  ];

  /// Featured marketplace-style Top Categories (title + browse group).
  static const topCategories = <(String title, String groupId)>[
    ('Diabetes', 'diabetes'),
    ('Digestive Care', 'liver'),
    ('Heart Care', 'heart'),
    ('Respiratory Care', 'lungs'),
    ('Kidney Care', 'kidney'),
    ('Joints & Muscle Care', 'bones'),
  ];

  static List<(String title, LabBrowseGroup group)> get featuredTopCategories {
    final out = <(String, LabBrowseGroup)>[];
    for (final entry in topCategories) {
      final group = findGroup(entry.$2);
      if (group != null) out.add((entry.$1, group));
    }
    return out;
  }

  static LabBrowseGroup? findGroup(String id) {
    for (final g in [...healthRisks, ...healthConditions, ...bodyOrgans]) {
      if (g.id == id) return g;
    }
    return null;
  }

  static LabHealthPackage? findPackage(String id) {
    for (final p in healthPackages) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const labFaqs = [
    ('Is fasting required?', 'Some tests require fasting. Each test card shows fasting requirements. Follow preparation instructions before sample collection.'),
    ('How is home sample collection done?', 'A certified phlebotomist visits your address at the selected slot, collects the sample safely, and transports it to the lab.'),
    ('When will reports be available?', 'Report delivery time is shown on each test. Most routine tests are available within 24–48 hours.'),
    ('Can I cancel or reschedule?', 'Yes. You can reschedule or cancel up to 2 hours before your slot from My Bookings.'),
    ('How do I download reports?', 'Reports appear in My Bookings and are also sent to your registered email once ready.'),
    ('Is NABL certification available?', 'NABL-accredited labs display a badge on their profile. Look for the NABL badge when choosing a lab.'),
  ];

  static const mockReviews = [
    ('Priya Sharma', 5, 'Quick home collection and reports delivered on time. Very professional staff.', '2 days ago'),
    ('Rahul Mehta', 4, 'Good pricing and easy booking. Lab visit was smooth.', '1 week ago'),
    ('Ananya Reddy', 5, 'Verified lab with clear instructions. Highly recommend for full body checkup.', '2 weeks ago'),
  ];
}
