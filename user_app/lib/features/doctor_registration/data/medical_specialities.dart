import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../features/labs/data/health_package_visuals.dart';
import '../../../features/labs/data/lab_test_illustrations.dart';

/// Catalog entry for the Find Doctors by Speciality grid.
class MedicalSpeciality {
  const MedicalSpeciality({
    required this.name,
    required this.slug,
    required this.description,
    required this.searchTerm,
    required this.order,
    required this.accent,
    required this.icon,
    this.illustration,
    this.imageAsset,
  });

  final String name;
  final String slug;
  final String description;
  /// Value sent to doctor search / specialization filter.
  final String searchTerm;
  final int order;
  final Color accent;
  final IconData icon;
  /// Outline SVG from [LabTestIllustrations], tinted with [accent].
  final String? illustration;
  /// Photographic organ PNG used when no matching SVG exists.
  final String? imageAsset;

  String get listingPath =>
      '${AppConstants.routeDoctorSearch}?speciality=$slug';
}

/// Most-searched specialities first. [searchTerm] matches [AppLists.specializations].
const medicalSpecialities = <MedicalSpeciality>[
  MedicalSpeciality(
    name: 'General Physician',
    slug: 'general-physician',
    description: 'Fever, infections & general care',
    searchTerm: 'General Physician',
    order: 1,
    accent: Color(0xFF208376),
    icon: Icons.medical_services_rounded,
    illustration: LabTestIllustrations.fullBody,
  ),
  MedicalSpeciality(
    name: 'Cardiology',
    slug: 'cardiology',
    description: 'Heart & blood vessels',
    searchTerm: 'Cardiology',
    order: 2,
    accent: Color(0xFFE53935),
    icon: Icons.monitor_heart_rounded,
    illustration: LabTestIllustrations.heart,
  ),
  MedicalSpeciality(
    name: 'Neurology',
    slug: 'neurology',
    description: 'Brain & nervous system',
    searchTerm: 'Neurology',
    order: 3,
    accent: Color(0xFF7E57C2),
    icon: Icons.psychology_rounded,
    illustration: LabTestIllustrations.brain,
  ),
  MedicalSpeciality(
    name: 'Orthopedics',
    slug: 'orthopedics',
    description: 'Bones, joints & sports injuries',
    searchTerm: 'Orthopedics',
    order: 4,
    accent: Color(0xFFFB8C00),
    icon: Icons.accessibility_new_rounded,
    illustration: LabTestIllustrations.bone,
  ),
  MedicalSpeciality(
    name: 'Dermatology',
    slug: 'dermatology',
    description: 'Skin, hair & nails',
    searchTerm: 'Dermatology',
    order: 5,
    accent: Color(0xFF5C6BC0),
    icon: Icons.face_rounded,
    illustration: LabTestIllustrations.skin,
  ),
  MedicalSpeciality(
    name: 'Pediatrics',
    slug: 'pediatrics',
    description: 'Child health & wellness',
    searchTerm: 'Pediatrics',
    order: 6,
    accent: Color(0xFF43A047),
    icon: Icons.child_care_rounded,
    illustration: LabTestIllustrations.vitamin,
  ),
  MedicalSpeciality(
    name: 'Gynecology',
    slug: 'gynecology',
    description: 'Women\'s health & pregnancy',
    searchTerm: 'Gynecology',
    order: 7,
    accent: Color(0xFFEC407A),
    icon: Icons.pregnant_woman_rounded,
    illustration: LabTestIllustrations.pregnancy,
  ),
  MedicalSpeciality(
    name: 'Dentistry',
    slug: 'dentistry',
    description: 'Teeth, gums & oral care',
    searchTerm: 'Dentistry',
    order: 8,
    accent: Color(0xFF00ACC1),
    icon: Icons.sentiment_satisfied_alt_rounded,
    illustration: LabTestIllustrations.tooth,
  ),
  MedicalSpeciality(
    name: 'ENT',
    slug: 'ent',
    description: 'Ear, nose & throat',
    searchTerm: 'ENT (Otolaryngology)',
    order: 9,
    accent: Color(0xFFF9A825),
    icon: Icons.hearing_rounded,
    imageAsset: OrganAssets.ear,
  ),
  MedicalSpeciality(
    name: 'Ophthalmology',
    slug: 'ophthalmology',
    description: 'Eyes & vision care',
    searchTerm: 'Ophthalmology',
    order: 10,
    accent: Color(0xFF1E88E5),
    icon: Icons.visibility_rounded,
    illustration: LabTestIllustrations.eye,
  ),
  MedicalSpeciality(
    name: 'Psychiatry',
    slug: 'psychiatry',
    description: 'Mental health & counselling',
    searchTerm: 'Psychiatry',
    order: 11,
    accent: Color(0xFF8E24AA),
    icon: Icons.psychology_alt_rounded,
    illustration: LabTestIllustrations.brain,
  ),
  MedicalSpeciality(
    name: 'Gastroenterology',
    slug: 'gastroenterology',
    description: 'Stomach, liver & digestion',
    searchTerm: 'Gastroenterology',
    order: 12,
    accent: Color(0xFF689F38),
    icon: Icons.restaurant_rounded,
    illustration: LabTestIllustrations.stomach,
  ),
  MedicalSpeciality(
    name: 'Pulmonology',
    slug: 'pulmonology',
    description: 'Lungs & respiratory care',
    searchTerm: 'Pulmonology',
    order: 13,
    accent: Color(0xFF039BE5),
    icon: Icons.air_rounded,
    illustration: LabTestIllustrations.lungs,
  ),
  MedicalSpeciality(
    name: 'Endocrinology',
    slug: 'endocrinology',
    description: 'Hormones, thyroid & diabetes',
    searchTerm: 'Endocrinology',
    order: 14,
    accent: Color(0xFF8D6E63),
    icon: Icons.water_drop_rounded,
    illustration: LabTestIllustrations.hormones,
  ),
  MedicalSpeciality(
    name: 'Nephrology',
    slug: 'nephrology',
    description: 'Kidneys & renal care',
    searchTerm: 'Nephrology',
    order: 15,
    accent: Color(0xFF00897B),
    icon: Icons.water_drop_outlined,
    illustration: LabTestIllustrations.kidney,
  ),
  MedicalSpeciality(
    name: 'Urology',
    slug: 'urology',
    description: 'Urinary system',
    searchTerm: 'Urology',
    order: 16,
    accent: Color(0xFF165C54),
    icon: Icons.water_drop_rounded,
    illustration: LabTestIllustrations.kidney,
  ),
  MedicalSpeciality(
    name: 'Oncology',
    slug: 'oncology',
    description: 'Cancer diagnosis & treatment',
    searchTerm: 'Oncology',
    order: 17,
    accent: Color(0xFFC2185B),
    icon: Icons.biotech_rounded,
    illustration: LabTestIllustrations.shield,
  ),
  MedicalSpeciality(
    name: 'Gynecologic Oncology',
    slug: 'gynecologic-oncology',
    description: 'Gynae cancers & tumours',
    searchTerm: 'Gynecologic Oncology',
    order: 18,
    accent: Color(0xFFD81B60),
    icon: Icons.female_rounded,
    illustration: LabTestIllustrations.reproductive,
  ),
  MedicalSpeciality(
    name: 'General Surgery',
    slug: 'general-surgery',
    description: 'Surgical procedures & care',
    searchTerm: 'General Surgery',
    order: 19,
    accent: Color(0xFF546E7A),
    icon: Icons.health_and_safety_rounded,
    illustration: LabTestIllustrations.liver,
  ),
  MedicalSpeciality(
    name: 'Neurosurgery',
    slug: 'neurosurgery',
    description: 'Brain & spine surgery',
    searchTerm: 'Neurosurgery',
    order: 20,
    accent: Color(0xFF5E35B1),
    icon: Icons.psychology_rounded,
    illustration: LabTestIllustrations.brain,
  ),
  MedicalSpeciality(
    name: 'Cardiothoracic Surgery',
    slug: 'cardiothoracic-surgery',
    description: 'Heart & chest surgery',
    searchTerm: 'Cardiothoracic Surgery',
    order: 21,
    accent: Color(0xFFD32F2F),
    icon: Icons.monitor_heart_rounded,
    illustration: LabTestIllustrations.ecg,
  ),
  MedicalSpeciality(
    name: 'Plastic Surgery',
    slug: 'plastic-surgery',
    description: 'Reconstructive & cosmetic care',
    searchTerm: 'Plastic Surgery',
    order: 22,
    accent: Color(0xFFEC407A),
    icon: Icons.face_retouching_natural_rounded,
    illustration: LabTestIllustrations.skin,
  ),
  MedicalSpeciality(
    name: 'Rheumatology',
    slug: 'rheumatology',
    description: 'Joints & arthritis',
    searchTerm: 'Rheumatology',
    order: 23,
    accent: Color(0xFFE91E63),
    icon: Icons.accessibility_new_rounded,
    illustration: LabTestIllustrations.bone,
  ),
  MedicalSpeciality(
    name: 'Hematology',
    slug: 'hematology',
    description: 'Blood disorders',
    searchTerm: 'Hematology',
    order: 24,
    accent: Color(0xFFC62828),
    icon: Icons.bloodtype_rounded,
    illustration: LabTestIllustrations.blood,
  ),
  MedicalSpeciality(
    name: 'Infectious Disease',
    slug: 'infectious-disease',
    description: 'Infections & immunity',
    searchTerm: 'Infectious Disease',
    order: 25,
    accent: Color(0xFF2E7D32),
    icon: Icons.coronavirus_rounded,
    illustration: LabTestIllustrations.virus,
  ),
  MedicalSpeciality(
    name: 'Radiology',
    slug: 'radiology',
    description: 'Imaging & diagnostics',
    searchTerm: 'Radiology',
    order: 26,
    accent: Color(0xFF3949AB),
    icon: Icons.monitor_rounded,
    illustration: LabTestIllustrations.shield,
  ),
  MedicalSpeciality(
    name: 'Anesthesiology',
    slug: 'anesthesiology',
    description: 'Pain relief & anaesthesia',
    searchTerm: 'Anesthesiology',
    order: 27,
    accent: Color(0xFF455A64),
    icon: Icons.airline_seat_flat_rounded,
    illustration: LabTestIllustrations.thermometer,
  ),
  MedicalSpeciality(
    name: 'Physiotherapy',
    slug: 'physiotherapy',
    description: 'Movement & rehab',
    searchTerm: 'Physiotherapy',
    order: 28,
    accent: Color(0xFF00838F),
    icon: Icons.self_improvement_rounded,
    imageAsset: OrganAssets.muscle,
  ),
  MedicalSpeciality(
    name: 'Nutrition & Dietetics',
    slug: 'nutrition-dietetics',
    description: 'Diet, weight & wellness',
    searchTerm: 'Nutrition & Dietetics',
    order: 29,
    accent: Color(0xFF7CB342),
    icon: Icons.restaurant_rounded,
    illustration: LabTestIllustrations.vitamin,
  ),
  MedicalSpeciality(
    name: 'Emergency Medicine',
    slug: 'emergency-medicine',
    description: 'Urgent & critical care',
    searchTerm: 'Emergency Medicine',
    order: 30,
    accent: Color(0xFFE53935),
    icon: Icons.emergency_rounded,
    illustration: LabTestIllustrations.energy,
  ),
];

/// Number of specialities shown before "View All" on compact screens.
const kMedicalSpecialityPreviewCount = 12;

const _specialityAliases = <String, String>{
  'pediatric': 'pediatrics',
  'paediatric': 'pediatrics',
  'mental': 'psychiatry',
  'ortho': 'orthopedics',
  'gynae': 'gynecology',
  'gyne': 'gynecology',
  'dermat': 'dermatology',
  'general': 'general-physician',
  'eye care': 'ophthalmology',
  'eye': 'ophthalmology',
  'ent (otolaryngology)': 'ent',
};

MedicalSpeciality? findMedicalSpeciality(String? value) {
  if (value == null) return null;
  final q = value.trim().toLowerCase();
  if (q.isEmpty) return null;
  final aliased = _specialityAliases[q] ?? q;

  for (final speciality in medicalSpecialities) {
    if (speciality.slug == aliased ||
        speciality.slug == q ||
        speciality.name.toLowerCase() == q ||
        speciality.searchTerm.toLowerCase() == q) {
      return speciality;
    }
  }
  return null;
}

/// Resolves a URL slug or display name into the API/filter search term.
String? resolveSpecialitySearchTerm(String? value) {
  return findMedicalSpeciality(value)?.searchTerm ??
      (value == null || value.trim().isEmpty ? null : value.trim());
}

String doctorSearchPathForSpeciality(
  String slug, {
  String? city,
  String? type,
}) {
  final params = <String, String>{'speciality': slug};
  if (city != null && city.isNotEmpty) params['city'] = city;
  if (type != null && type.isNotEmpty) params['type'] = type;
  return '${AppConstants.routeDoctorSearch}?${Uri(queryParameters: params).query}';
}
