import 'package:flutter/material.dart';

/// Background decoration pattern for premium health test cards.
enum HealthCardPattern { ecg, dna, dots, hexagon }

/// Visual theme for a health package / browse card.
class HealthPackageVisual {
  const HealthPackageVisual({
    required this.organAsset,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    required this.pattern,
    this.subtitle = 'Advanced Screening',
    this.features = const ['Home Collection', 'NABL Certified'],
  });

  final String organAsset;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
  final HealthCardPattern pattern;
  final String subtitle;
  final List<String> features;

  LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      );
}

const _organs = 'assets/images/organ';

/// Organ illustration filenames in [assets/images/organ] (background removed).
abstract final class OrganAssets {
  static const heart = '$_organs/heart-removebg-preview.png';
  static const kidney = '$_organs/kidney-removebg-preview.png';
  static const liver = '$_organs/liver-removebg-preview.png';
  static const lungs = '$_organs/lungs-removebg-preview.png';
  static const spine = '$_organs/spine-removebg-preview.png';
  static const blood = '$_organs/blood-removebg-preview.png';
  static const thyroid = '$_organs/thyroid-removebg-preview.png';
  static const eye = '$_organs/eye-removebg-preview.png';
  static const bone = '$_organs/bone-removebg-preview.png';
  static const stomach = '$_organs/stomach-removebg-preview.png';
  static const pancreas = '$_organs/pancres-removebg-preview.png';
  static const diabetes = '$_organs/diabties-removebg-preview.png';
  static const dengue = '$_organs/dengue-removebg-preview.png';
  static const fever = '$_organs/fever-removebg-preview.png';
  static const allergy = '$_organs/allery-removebg-preview.png';
  static const cholesterol = '$_organs/chelestoral-removebg-preview.png';
  static const bloodPressure = '$_organs/bloodpressure-removebg-preview.png';
  static const pregnancy = '$_organs/pregnancy-removebg-preview.png';
  static const vitamin = '$_organs/vitamin-removebg-preview.png';
  static const immuneCell = '$_organs/immune_cell-removebg-preview.png';
  static const immuneSystem = '$_organs/imune_system-removebg-preview.png';
  static const skin = '$_organs/skin-removebg-preview.png';
  static const tooth = '$_organs/tooth-removebg-preview.png';
  static const muscle = '$_organs/muscle-removebg-preview.png';
  static const dna = '$_organs/DNA-removebg-preview.png';
  static const gallbladder = '$_organs/gallblader-removebg-preview.png';
  static const ear = '$_organs/ear-removebg-preview.png';
}

class HealthPackageVisuals {
  HealthPackageVisuals._();

  static const _defaults = HealthPackageVisual(
    organAsset: OrganAssets.heart,
    gradientStart: Color(0xFFFFF5F7),
    gradientEnd: Color(0xFFFFE4EC),
    accent: Color(0xFFEF4444),
    pattern: HealthCardPattern.ecg,
  );

  static HealthPackageVisual forId(String id) {
    return _byId[id] ?? _fallbackForId(id);
  }

  static HealthPackageVisual _fallbackForId(String id) {
    if (id.contains('kidney')) return _byId['kidney']!;
    if (id.contains('liver') || id.contains('fatty')) return _byId['liver']!;
    if (id.contains('lung') || id.contains('asthma')) return _byId['lungs']!;
    if (id.contains('brain') || id.contains('hormon')) return _byId['brain']!;
    if (id.contains('blood') || id.contains('anemia')) return _byId['blood']!;
    if (id.contains('thyroid')) return _byId['thyroid']!;
    if (id.contains('eye')) return _byId['eye']!;
    if (id.contains('bone') || id.contains('arthrit')) return _byId['bone']!;
    if (id.contains('stomach')) return _byId['stomach']!;
    if (id.contains('diabetes')) return _byId['diabetes-risk']!;
    if (id.contains('dengue') || id.contains('malaria')) {
      return _byId['dengue']!;
    }
    if (id.contains('covid') || id.contains('virus')) return _byId['covid']!;
    if (id.contains('pregnancy') || id.contains('pcos') || id.contains('womens')) {
      return _byId['pregnancy']!;
    }
    if (id.contains('vitamin')) return _byId['vitamin-risk']!;
    if (id.contains('allergy')) return _byId['allergy']!;
    if (id.contains('fever')) return _byId['fever']!;
    if (id.contains('cholesterol')) return _byId['cholesterol']!;
    if (id.contains('hypertension')) return _byId['hypertension']!;
    if (id.contains('heart')) return _byId['heart-risk']!;
    return _defaults;
  }

  static const _byId = <String, HealthPackageVisual>{
    'heart-risk': HealthPackageVisual(
      organAsset: OrganAssets.heart,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE8EE),
      accent: Color(0xFFEF4444),
      pattern: HealthCardPattern.ecg,
      subtitle: 'Full Heart Screening',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'heart': HealthPackageVisual(
      organAsset: OrganAssets.heart,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE8EE),
      accent: Color(0xFFEF4444),
      pattern: HealthCardPattern.ecg,
      subtitle: 'Cardiac Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'kidney-risk': HealthPackageVisual(
      organAsset: OrganAssets.kidney,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF3E8FF),
      accent: Color(0xFF8B5CF6),
      pattern: HealthCardPattern.dna,
      subtitle: 'Kidney Function Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'kidney': HealthPackageVisual(
      organAsset: OrganAssets.kidney,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF3E8FF),
      accent: Color(0xFF8B5CF6),
      pattern: HealthCardPattern.dna,
      subtitle: 'KFT Advanced',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'kidney-disease': HealthPackageVisual(
      organAsset: OrganAssets.kidney,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF3E8FF),
      accent: Color(0xFF8B5CF6),
      pattern: HealthCardPattern.dna,
      subtitle: 'Renal Health Check',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'liver-risk': HealthPackageVisual(
      organAsset: OrganAssets.liver,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFF0E6),
      accent: Color(0xFFFB923C),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Liver Function Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'liver': HealthPackageVisual(
      organAsset: OrganAssets.liver,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFF0E6),
      accent: Color(0xFFFB923C),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'LFT Advanced',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'fatty-liver': HealthPackageVisual(
      organAsset: OrganAssets.liver,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFF0E6),
      accent: Color(0xFFFB923C),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Fatty Liver Screening',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'lung-health': HealthPackageVisual(
      organAsset: OrganAssets.lungs,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F7FA),
      accent: Color(0xFF06B6D4),
      pattern: HealthCardPattern.dots,
      subtitle: 'Respiratory Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'lungs': HealthPackageVisual(
      organAsset: OrganAssets.lungs,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F7FA),
      accent: Color(0xFF06B6D4),
      pattern: HealthCardPattern.dots,
      subtitle: 'Pulmonary Screening',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'asthma': HealthPackageVisual(
      organAsset: OrganAssets.lungs,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F7FA),
      accent: Color(0xFF06B6D4),
      pattern: HealthCardPattern.dots,
      subtitle: 'Allergy & Lung Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'brain': HealthPackageVisual(
      organAsset: OrganAssets.spine,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF3E8FF),
      accent: Color(0xFF9333EA),
      pattern: HealthCardPattern.dna,
      subtitle: 'Neuro Health Markers',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'hormonal-risk': HealthPackageVisual(
      organAsset: OrganAssets.spine,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF3E8FF),
      accent: Color(0xFF9333EA),
      pattern: HealthCardPattern.dna,
      subtitle: 'Hormone Profile',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'hormones': HealthPackageVisual(
      organAsset: OrganAssets.spine,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF3E8FF),
      accent: Color(0xFF9333EA),
      pattern: HealthCardPattern.dna,
      subtitle: 'Endocrine Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'blood': HealthPackageVisual(
      organAsset: OrganAssets.blood,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE4E6),
      accent: Color(0xFFDC2626),
      pattern: HealthCardPattern.dots,
      subtitle: 'Complete Blood Count',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'anemia': HealthPackageVisual(
      organAsset: OrganAssets.blood,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE4E6),
      accent: Color(0xFFDC2626),
      pattern: HealthCardPattern.dots,
      subtitle: 'Iron & CBC Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'thyroid-risk': HealthPackageVisual(
      organAsset: OrganAssets.thyroid,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F2FE),
      accent: Color(0xFF0EA5E9),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Thyroid Profile',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'thyroid': HealthPackageVisual(
      organAsset: OrganAssets.thyroid,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F2FE),
      accent: Color(0xFF0EA5E9),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'TSH & Antibodies',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'thyroid-organ': HealthPackageVisual(
      organAsset: OrganAssets.thyroid,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F2FE),
      accent: Color(0xFF0EA5E9),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Thyroid Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'eyes': HealthPackageVisual(
      organAsset: OrganAssets.eye,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F2FE),
      accent: Color(0xFF0284C7),
      pattern: HealthCardPattern.dots,
      subtitle: 'Vision Health Markers',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'eye': HealthPackageVisual(
      organAsset: OrganAssets.eye,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE0F2FE),
      accent: Color(0xFF0284C7),
      pattern: HealthCardPattern.dots,
      subtitle: 'Eye Care Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'bone-risk': HealthPackageVisual(
      organAsset: OrganAssets.bone,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFEEF2FF),
      accent: Color(0xFF6366F1),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Bone Density Markers',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'bones': HealthPackageVisual(
      organAsset: OrganAssets.bone,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFEEF2FF),
      accent: Color(0xFF6366F1),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Vitamin D & Calcium',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'arthritis': HealthPackageVisual(
      organAsset: OrganAssets.bone,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFEEF2FF),
      accent: Color(0xFF6366F1),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Joint Health Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'stomach': HealthPackageVisual(
      organAsset: OrganAssets.stomach,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFF7ED),
      accent: Color(0xFFF97316),
      pattern: HealthCardPattern.dots,
      subtitle: 'Digestive Screening',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'diabetes-risk': HealthPackageVisual(
      organAsset: OrganAssets.diabetes,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFF7ED),
      accent: Color(0xFFEA580C),
      pattern: HealthCardPattern.ecg,
      subtitle: '18 Parameters Included',
      features: ['Home Collection', 'Fasting Required'],
    ),
    'diabetes': HealthPackageVisual(
      organAsset: OrganAssets.diabetes,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFF7ED),
      accent: Color(0xFFEA580C),
      pattern: HealthCardPattern.ecg,
      subtitle: 'Glucose & HbA1c',
      features: ['Home Collection', 'Fasting Required'],
    ),
    'dengue': HealthPackageVisual(
      organAsset: OrganAssets.dengue,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFF7ED),
      accent: Color(0xFFD97706),
      pattern: HealthCardPattern.dots,
      subtitle: 'NS1 Antigen Test',
      features: ['Home Collection', 'Fast Reports'],
    ),
    'malaria': HealthPackageVisual(
      organAsset: OrganAssets.blood,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF3E8FF),
      accent: Color(0xFF7C3AED),
      pattern: HealthCardPattern.dots,
      subtitle: 'Parasite Screening',
      features: ['Home Collection', 'Fast Reports'],
    ),
    'covid': HealthPackageVisual(
      organAsset: OrganAssets.immuneSystem,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFEFF6FF),
      accent: Color(0xFF2563EB),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'RT-PCR & Antigen',
      features: ['Home Collection', 'Fast Reports'],
    ),
    'pregnancy': HealthPackageVisual(
      organAsset: OrganAssets.pregnancy,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFDF2F8),
      accent: Color(0xFFDB2777),
      pattern: HealthCardPattern.dna,
      subtitle: 'Prenatal Markers',
      features: ['Home Collection', 'Doctor Recommended'],
    ),
    'pcos': HealthPackageVisual(
      organAsset: OrganAssets.pregnancy,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFDF2F8),
      accent: Color(0xFFBE185D),
      pattern: HealthCardPattern.dna,
      subtitle: 'Hormone Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'womens': HealthPackageVisual(
      organAsset: OrganAssets.pregnancy,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFDF2F8),
      accent: Color(0xFFDB2777),
      pattern: HealthCardPattern.dna,
      subtitle: 'Women Wellness Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'vitamin-risk': HealthPackageVisual(
      organAsset: OrganAssets.vitamin,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFFBEB),
      accent: Color(0xFFF59E0B),
      pattern: HealthCardPattern.dots,
      subtitle: 'Vitamin D & B12',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'vitamin-d': HealthPackageVisual(
      organAsset: OrganAssets.bone,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFFBEB),
      accent: Color(0xFFF59E0B),
      pattern: HealthCardPattern.dots,
      subtitle: 'Vitamin D Test',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'vitamin-b12': HealthPackageVisual(
      organAsset: OrganAssets.vitamin,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF0FDFA),
      accent: Color(0xFF0D9488),
      pattern: HealthCardPattern.dots,
      subtitle: 'B12 Deficiency Test',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'allergy': HealthPackageVisual(
      organAsset: OrganAssets.allergy,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFECFDF5),
      accent: Color(0xFF059669),
      pattern: HealthCardPattern.dots,
      subtitle: 'IgE Allergy Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'fever': HealthPackageVisual(
      organAsset: OrganAssets.fever,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFEBEE),
      accent: Color(0xFFDC2626),
      pattern: HealthCardPattern.ecg,
      subtitle: 'Fever Workup Panel',
      features: ['Home Collection', 'Fast Reports'],
    ),
    'cholesterol': HealthPackageVisual(
      organAsset: OrganAssets.cholesterol,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE8EE),
      accent: Color(0xFFEF4444),
      pattern: HealthCardPattern.ecg,
      subtitle: 'Lipid Profile',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'cholesterol-risk': HealthPackageVisual(
      organAsset: OrganAssets.cholesterol,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE8EE),
      accent: Color(0xFFEF4444),
      pattern: HealthCardPattern.ecg,
      subtitle: 'Lipid Screening',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'hypertension': HealthPackageVisual(
      organAsset: OrganAssets.bloodPressure,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE8EE),
      accent: Color(0xFFB91C1C),
      pattern: HealthCardPattern.ecg,
      subtitle: 'Cardio-Renal Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'hypertension-risk': HealthPackageVisual(
      organAsset: OrganAssets.bloodPressure,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFE8EE),
      accent: Color(0xFFB91C1C),
      pattern: HealthCardPattern.ecg,
      subtitle: 'BP Risk Markers',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'cancer-risk': HealthPackageVisual(
      organAsset: OrganAssets.immuneCell,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF5F3FF),
      accent: Color(0xFF7C3AED),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Cancer Markers',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'full-body': HealthPackageVisual(
      organAsset: OrganAssets.dna,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFE6F7EE),
      accent: Color(0xFF19A552),
      pattern: HealthCardPattern.hexagon,
      subtitle: '60+ Parameters',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'mens': HealthPackageVisual(
      organAsset: OrganAssets.muscle,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFEFF6FF),
      accent: Color(0xFF2563EB),
      pattern: HealthCardPattern.ecg,
      subtitle: "Men's Wellness",
      features: ['Home Collection', 'NABL Certified'],
    ),
    'obesity-risk': HealthPackageVisual(
      organAsset: OrganAssets.stomach,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF0FDFA),
      accent: Color(0xFF0D9488),
      pattern: HealthCardPattern.dots,
      subtitle: 'Metabolic Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'skin': HealthPackageVisual(
      organAsset: OrganAssets.skin,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFDF2F8),
      accent: Color(0xFFDB2777),
      pattern: HealthCardPattern.dots,
      subtitle: 'Dermatology Panel',
      features: ['Home Collection', 'NABL Certified'],
    ),
    'dental': HealthPackageVisual(
      organAsset: OrganAssets.tooth,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF0FDFA),
      accent: Color(0xFF14B8A6),
      pattern: HealthCardPattern.hexagon,
      subtitle: 'Oral Health Markers',
      features: ['Home Collection', 'NABL Certified'],
    ),
  };
}
