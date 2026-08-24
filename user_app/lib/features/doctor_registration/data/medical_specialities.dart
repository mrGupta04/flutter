import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../features/labs/data/health_package_visuals.dart';

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
    required this.imageAsset,
    this.illustration,
  });

  final String name;
  final String slug;
  final String description;
  /// Value sent to doctor search / specialization filter.
  final String searchTerm;
  final int order;
  final Color accent;
  final IconData icon;
  /// Photographic organ PNG used as the specialty logo.
  final String imageAsset;
  /// Optional outline SVG fallback.
  final String? illustration;

  String get listingPath =>
      '${AppConstants.routeDoctorSearch}?speciality=$slug';
}

/// Browse catalog matching the Find Specialists list. [searchTerm] matches
/// [AppLists.specializations] (including older registration labels).
const medicalSpecialities = <MedicalSpeciality>[
  MedicalSpeciality(
    name: 'Algiatrist',
    slug: 'algiatrist',
    description: 'Pain Care',
    searchTerm: 'Pain Management',
    order: 39,
    accent: Color(0xFFE53935),
    icon: Icons.healing_rounded,
    imageAsset: OrganAssets.spine,
  ),
  MedicalSpeciality(
    name: 'Allergy and Immunology',
    slug: 'allergy-and-immunology',
    description: 'Allergy & Immunity',
    searchTerm: 'Allergy & Immunology',
    order: 26,
    accent: Color(0xFF8E24AA),
    icon: Icons.coronavirus_rounded,
    imageAsset: OrganAssets.allergy,
  ),
  MedicalSpeciality(
    name: 'Andrology',
    slug: 'andrology',
    description: "Men's Health",
    searchTerm: 'Andrology',
    order: 41,
    accent: Color(0xFF1E88E5),
    icon: Icons.male_rounded,
    imageAsset: OrganAssets.kidney,
  ),
  MedicalSpeciality(
    name: 'Anesthesiology',
    slug: 'anesthesiology',
    description: 'Anesthesia Care',
    searchTerm: 'Anesthesiology',
    order: 40,
    accent: Color(0xFF7E57C2),
    icon: Icons.airline_seat_flat_rounded,
    imageAsset: OrganAssets.fever,
  ),
  MedicalSpeciality(
    name: 'Ayurvedic and Unani Medicine',
    slug: 'ayurvedic-and-unani-medicine',
    description: 'Traditional Medicine',
    searchTerm: 'Ayurveda',
    order: 25,
    accent: Color(0xFF00897B),
    icon: Icons.spa_rounded,
    imageAsset: OrganAssets.immuneSystem,
  ),
  MedicalSpeciality(
    name: 'Cardiology',
    slug: 'cardiology',
    description: 'Heart Specialist',
    searchTerm: 'Cardiology',
    order: 3,
    accent: Color(0xFFE53935),
    icon: Icons.monitor_heart_rounded,
    imageAsset: OrganAssets.heart,
  ),
  MedicalSpeciality(
    name: 'CTVS',
    slug: 'ctvs',
    description: 'Heart Surgery',
    searchTerm: 'Cardiothoracic Surgery',
    order: 34,
    accent: Color(0xFFD32F2F),
    icon: Icons.favorite_rounded,
    imageAsset: OrganAssets.heart,
  ),
  MedicalSpeciality(
    name: 'Chest Specialist',
    slug: 'chest-specialist',
    description: 'Pulmonology',
    searchTerm: 'Chest Specialist',
    order: 24,
    accent: Color(0xFF00897B),
    icon: Icons.air_rounded,
    imageAsset: OrganAssets.lungs,
  ),
  MedicalSpeciality(
    name: 'Critical Care Medicine',
    slug: 'critical-care-medicine',
    description: 'Intensive Care',
    searchTerm: 'Critical Care Medicine',
    order: 42,
    accent: Color(0xFFE53935),
    icon: Icons.emergency_rounded,
    imageAsset: OrganAssets.bloodPressure,
  ),
  MedicalSpeciality(
    name: 'Dentistry (Oral and Maxillofacial Surgery)',
    slug: 'dentistry',
    description: 'Dental & Jaw Care',
    searchTerm: 'Dentistry',
    order: 18,
    accent: Color(0xFF00ACC1),
    icon: Icons.sentiment_satisfied_alt_rounded,
    imageAsset: OrganAssets.tooth,
  ),
  MedicalSpeciality(
    name: 'Dermatology',
    slug: 'dermatology',
    description: 'Skin Care',
    searchTerm: 'Dermatology',
    order: 6,
    accent: Color(0xFF5C6BC0),
    icon: Icons.face_rounded,
    imageAsset: OrganAssets.skin,
  ),
  MedicalSpeciality(
    name: 'Diabetology',
    slug: 'diabetology',
    description: 'Diabetes Care',
    searchTerm: 'Diabetology',
    order: 15,
    accent: Color(0xFF8D6E63),
    icon: Icons.water_drop_rounded,
    imageAsset: OrganAssets.diabetes,
  ),
  MedicalSpeciality(
    name: 'Emergency Medicine',
    slug: 'emergency-medicine',
    description: 'Urgent & Critical Care',
    searchTerm: 'Emergency Medicine',
    order: 23,
    accent: Color(0xFFE53935),
    icon: Icons.emergency_rounded,
    imageAsset: OrganAssets.blood,
  ),
  MedicalSpeciality(
    name: 'Endocrinology',
    slug: 'endocrinology',
    description: 'Hormones, Thyroid & Diabetes',
    searchTerm: 'Endocrinology',
    order: 14,
    accent: Color(0xFF8D6E63),
    icon: Icons.water_drop_rounded,
    imageAsset: OrganAssets.thyroid,
  ),
  MedicalSpeciality(
    name: 'ENT',
    slug: 'ent',
    description: 'Ear, Nose, Throat',
    searchTerm: 'ENT (Otolaryngology)',
    order: 9,
    accent: Color(0xFFF9A825),
    icon: Icons.hearing_rounded,
    imageAsset: OrganAssets.ear,
  ),
  MedicalSpeciality(
    name: 'Family Medicine',
    slug: 'family-medicine',
    description: 'Family Care',
    searchTerm: 'Family Medicine',
    order: 22,
    accent: Color(0xFF43A047),
    icon: Icons.family_restroom_rounded,
    imageAsset: OrganAssets.vitamin,
  ),
  MedicalSpeciality(
    name: 'Gastroenterology',
    slug: 'gastroenterology',
    description: 'Digestive Care',
    searchTerm: 'Gastroenterology',
    order: 10,
    accent: Color(0xFF689F38),
    icon: Icons.restaurant_rounded,
    imageAsset: OrganAssets.stomach,
  ),
  MedicalSpeciality(
    name: 'General Medicine',
    slug: 'general-medicine',
    description: 'Primary Care',
    searchTerm: 'General Medicine',
    order: 2,
    accent: Color(0xFF19A552),
    icon: Icons.medical_services_rounded,
    imageAsset: OrganAssets.bloodPressure,
  ),
  MedicalSpeciality(
    name: 'General Physician',
    slug: 'general-physician',
    description: 'Primary Care',
    searchTerm: 'General Physician',
    order: 1,
    accent: Color(0xFF546E7A),
    icon: Icons.person_rounded,
    imageAsset: OrganAssets.immuneSystem,
  ),
  MedicalSpeciality(
    name: 'General Surgery',
    slug: 'general-surgery',
    description: 'Surgical Care',
    searchTerm: 'General Surgery',
    order: 17,
    accent: Color(0xFF546E7A),
    icon: Icons.health_and_safety_rounded,
    imageAsset: OrganAssets.gallbladder,
  ),
  MedicalSpeciality(
    name: 'Hematology',
    slug: 'hematology',
    description: 'Blood Disorders',
    searchTerm: 'Hematology',
    order: 28,
    accent: Color(0xFFC62828),
    icon: Icons.bloodtype_rounded,
    imageAsset: OrganAssets.blood,
  ),
  MedicalSpeciality(
    name: 'Hepatology',
    slug: 'hepatology',
    description: 'Liver Care',
    searchTerm: 'Hepatology',
    order: 29,
    accent: Color(0xFF689F38),
    icon: Icons.monitor_heart_outlined,
    imageAsset: OrganAssets.liver,
  ),
  MedicalSpeciality(
    name: 'Infertility & IVF Specialist (Gynecology)',
    slug: 'infertility-ivf',
    description: 'Fertility Care',
    searchTerm: 'Infertility & IVF Specialist (Gynecology)',
    order: 30,
    accent: Color(0xFFEC407A),
    icon: Icons.child_friendly_rounded,
    imageAsset: OrganAssets.pregnancy,
  ),
  MedicalSpeciality(
    name: 'Kidney Transplant',
    slug: 'kidney-transplant',
    description: 'Specialist care',
    searchTerm: 'Kidney Transplant',
    order: 46,
    accent: Color(0xFFEC407A),
    icon: Icons.volunteer_activism_rounded,
    imageAsset: OrganAssets.kidney,
  ),
  MedicalSpeciality(
    name: 'Laparoscopy',
    slug: 'laparoscopy',
    description: 'Minimally Invasive Surgery',
    searchTerm: 'Laparoscopy',
    order: 43,
    accent: Color(0xFF5C6BC0),
    icon: Icons.cut_rounded,
    imageAsset: OrganAssets.gallbladder,
  ),
  MedicalSpeciality(
    name: 'Laparoscopic Urologic Surgery',
    slug: 'laparoscopic-urologic-surgery',
    description: 'Urologic Surgery',
    searchTerm: 'Laparoscopic Urologic Surgery',
    order: 44,
    accent: Color(0xFFFB8C00),
    icon: Icons.water_drop_rounded,
    imageAsset: OrganAssets.kidney,
  ),
  MedicalSpeciality(
    name: 'Laser treatment',
    slug: 'laser-treatment',
    description: 'Laser Care',
    searchTerm: 'Laser treatment',
    order: 45,
    accent: Color(0xFFEC407A),
    icon: Icons.auto_fix_high_rounded,
    imageAsset: OrganAssets.skin,
  ),
  MedicalSpeciality(
    name: 'Neonatology',
    slug: 'neonatology',
    description: 'Newborn Care',
    searchTerm: 'Neonatology',
    order: 31,
    accent: Color(0xFF78909C),
    icon: Icons.child_care_rounded,
    imageAsset: OrganAssets.pregnancy,
  ),
  MedicalSpeciality(
    name: 'Nephrology',
    slug: 'nephrology',
    description: 'Kidney Specialist',
    searchTerm: 'Nephrology',
    order: 19,
    accent: Color(0xFF00897B),
    icon: Icons.water_drop_outlined,
    imageAsset: OrganAssets.kidney,
  ),
  MedicalSpeciality(
    name: 'Neurology',
    slug: 'neurology',
    description: 'Brain & Nerves',
    searchTerm: 'Neurology',
    order: 4,
    accent: Color(0xFF7E57C2),
    icon: Icons.psychology_rounded,
    imageAsset: OrganAssets.spine,
  ),
  MedicalSpeciality(
    name: 'Neuropsychiatry',
    slug: 'neuropsychiatry',
    description: 'Brain & Mental Health',
    searchTerm: 'Neuropsychiatry',
    order: 33,
    accent: Color(0xFF5C6BC0),
    icon: Icons.psychology_alt_rounded,
    imageAsset: OrganAssets.immuneCell,
  ),
  MedicalSpeciality(
    name: 'Neurosurgeon',
    slug: 'neurosurgeon',
    description: 'Brain Surgery',
    searchTerm: 'Neurosurgery',
    order: 32,
    accent: Color(0xFFFB8C00),
    icon: Icons.psychology_rounded,
    imageAsset: OrganAssets.bone,
  ),
  MedicalSpeciality(
    name: 'Obstetrics and Gynecology (OB-GYN)',
    slug: 'obstetrics-and-gynecology',
    description: "Women's Health",
    searchTerm: 'Gynecology & Obstetrics',
    order: 8,
    accent: Color(0xFFEC407A),
    icon: Icons.pregnant_woman_rounded,
    imageAsset: OrganAssets.pregnancy,
  ),
  MedicalSpeciality(
    name: 'Oncological Surgeon',
    slug: 'oncological-surgeon',
    description: 'Cancer Surgery',
    searchTerm: 'Surgical Oncology',
    order: 47,
    accent: Color(0xFFFB8C00),
    icon: Icons.biotech_rounded,
    imageAsset: OrganAssets.dna,
  ),
  MedicalSpeciality(
    name: 'Oncology',
    slug: 'oncology',
    description: 'Cancer Care',
    searchTerm: 'Oncology',
    order: 20,
    accent: Color(0xFFC2185B),
    icon: Icons.biotech_rounded,
    imageAsset: OrganAssets.dna,
  ),
  MedicalSpeciality(
    name: 'Ophthalmic Surgery',
    slug: 'ophthalmic-surgery',
    description: 'Eye Surgery',
    searchTerm: 'Ophthalmic Surgery',
    order: 48,
    accent: Color(0xFF43A047),
    icon: Icons.visibility_rounded,
    imageAsset: OrganAssets.eye,
  ),
  MedicalSpeciality(
    name: 'Ophthalmology',
    slug: 'ophthalmology',
    description: 'Eye Care',
    searchTerm: 'Ophthalmology',
    order: 11,
    accent: Color(0xFF1E88E5),
    icon: Icons.visibility_rounded,
    imageAsset: OrganAssets.eye,
  ),
  MedicalSpeciality(
    name: 'Optometrist',
    slug: 'optometrist',
    description: 'Vision Care',
    searchTerm: 'Optometrist',
    order: 36,
    accent: Color(0xFF43A047),
    icon: Icons.remove_red_eye_outlined,
    imageAsset: OrganAssets.eye,
  ),
  MedicalSpeciality(
    name: 'Orthopedics',
    slug: 'orthopedics',
    description: 'Bone & Joint',
    searchTerm: 'Orthopedics',
    order: 5,
    accent: Color(0xFFFB8C00),
    icon: Icons.accessibility_new_rounded,
    imageAsset: OrganAssets.bone,
  ),
  MedicalSpeciality(
    name: 'Pediatric Hemato-Oncologist',
    slug: 'pediatric-hemato-oncologist',
    description: 'Specialist care',
    searchTerm: 'Pediatric Hemato-Oncologist',
    order: 49,
    accent: Color(0xFF1E88E5),
    icon: Icons.child_care_rounded,
    imageAsset: OrganAssets.blood,
  ),
  MedicalSpeciality(
    name: 'Pediatrics',
    slug: 'pediatrics',
    description: 'Child Care',
    searchTerm: 'Pediatrics',
    order: 7,
    accent: Color(0xFFEC407A),
    icon: Icons.child_care_rounded,
    imageAsset: OrganAssets.vitamin,
  ),
  MedicalSpeciality(
    name: 'Physiotherapy',
    slug: 'physiotherapy',
    description: 'Physical Therapy',
    searchTerm: 'Physiotherapy',
    order: 21,
    accent: Color(0xFF1E88E5),
    icon: Icons.self_improvement_rounded,
    imageAsset: OrganAssets.muscle,
  ),
  MedicalSpeciality(
    name: 'Plastic Surgery',
    slug: 'plastic-surgery',
    description: 'Aesthetic Surgery',
    searchTerm: 'Plastic Surgery',
    order: 38,
    accent: Color(0xFF29B6F6),
    icon: Icons.face_retouching_natural_rounded,
    imageAsset: OrganAssets.skin,
  ),
  MedicalSpeciality(
    name: 'PRP Therapy (Hair transplant)',
    slug: 'prp-therapy',
    description: 'Hair Restoration',
    searchTerm: 'PRP Therapy (Hair transplant)',
    order: 50,
    accent: Color(0xFFEC407A),
    icon: Icons.content_cut_rounded,
    imageAsset: OrganAssets.skin,
  ),
  MedicalSpeciality(
    name: 'Psychiatry',
    slug: 'psychiatry',
    description: 'Mental Health',
    searchTerm: 'Psychiatry',
    order: 12,
    accent: Color(0xFF8E24AA),
    icon: Icons.psychology_alt_rounded,
    imageAsset: OrganAssets.immuneCell,
  ),
  MedicalSpeciality(
    name: 'Pulmonology',
    slug: 'pulmonology',
    description: 'Chest & Lungs',
    searchTerm: 'Pulmonology',
    order: 13,
    accent: Color(0xFF00897B),
    icon: Icons.air_rounded,
    imageAsset: OrganAssets.lungs,
  ),
  MedicalSpeciality(
    name: 'Radiology',
    slug: 'radiology',
    description: 'Imaging Care',
    searchTerm: 'Radiology',
    order: 35,
    accent: Color(0xFF43A047),
    icon: Icons.monitor_rounded,
    imageAsset: OrganAssets.bone,
  ),
  MedicalSpeciality(
    name: 'Reconstructive Surgery',
    slug: 'reconstructive-surgery',
    description: 'Surgical Repair',
    searchTerm: 'Reconstructive Surgery',
    order: 51,
    accent: Color(0xFF1E88E5),
    icon: Icons.healing_rounded,
    imageAsset: OrganAssets.muscle,
  ),
  MedicalSpeciality(
    name: 'Rehabilitation Medicine',
    slug: 'rehabilitation-medicine',
    description: 'Recovery Care',
    searchTerm: 'Rehabilitation Medicine',
    order: 52,
    accent: Color(0xFFFB8C00),
    icon: Icons.accessible_rounded,
    imageAsset: OrganAssets.muscle,
  ),
  MedicalSpeciality(
    name: 'Reproductive Endocrinology (IVF)',
    slug: 'reproductive-endocrinology',
    description: 'Fertility Hormones',
    searchTerm: 'Reproductive Endocrinology (IVF)',
    order: 53,
    accent: Color(0xFF7E57C2),
    icon: Icons.child_friendly_rounded,
    imageAsset: OrganAssets.pregnancy,
  ),
  MedicalSpeciality(
    name: 'Rheumatology',
    slug: 'rheumatology',
    description: 'Joints & Arthritis',
    searchTerm: 'Rheumatology',
    order: 27,
    accent: Color(0xFFEC407A),
    icon: Icons.accessibility_new_rounded,
    imageAsset: OrganAssets.bone,
  ),
  MedicalSpeciality(
    name: 'Skin & Beauty Specialist',
    slug: 'skin-and-beauty',
    description: 'Skin & Beauty',
    searchTerm: 'Skin & Beauty Specialist',
    order: 37,
    accent: Color(0xFF8E24AA),
    icon: Icons.face_retouching_natural_rounded,
    imageAsset: OrganAssets.skin,
  ),
  MedicalSpeciality(
    name: 'Sonology',
    slug: 'sonology',
    description: 'Ultrasound Imaging',
    searchTerm: 'Sonology',
    order: 54,
    accent: Color(0xFF00897B),
    icon: Icons.graphic_eq_rounded,
    imageAsset: OrganAssets.pregnancy,
  ),
  MedicalSpeciality(
    name: 'Trauma Surgery',
    slug: 'trauma-surgery',
    description: 'Trauma Care',
    searchTerm: 'Trauma Surgery',
    order: 55,
    accent: Color(0xFFE53935),
    icon: Icons.local_hospital_rounded,
    imageAsset: OrganAssets.bone,
  ),
  MedicalSpeciality(
    name: 'Urology',
    slug: 'urology',
    description: 'Urinary System',
    searchTerm: 'Urology',
    order: 16,
    accent: Color(0xFF00897B),
    icon: Icons.water_drop_rounded,
    imageAsset: OrganAssets.kidney,
  ),
];

/// Number of specialities shown before "View All" on compact screens.
const kMedicalSpecialityPreviewCount = 12;

const _specialityAliases = <String, String>{
  'pediatric': 'pediatrics',
  'paediatric': 'pediatrics',
  'mental': 'psychiatry',
  'ortho': 'orthopedics',
  'gynae': 'obstetrics-and-gynecology',
  'gyne': 'obstetrics-and-gynecology',
  'gynecology': 'obstetrics-and-gynecology',
  'gynecology & obstetrics': 'obstetrics-and-gynecology',
  'obstetrics': 'obstetrics-and-gynecology',
  'dermat': 'dermatology',
  'general': 'general-physician',
  'eye care': 'ophthalmology',
  'eye': 'ophthalmology',
  'ent (otolaryngology)': 'ent',
  'otolaryngology': 'ent',
  'pain management': 'algiatrist',
  'algiatry': 'algiatrist',
  'allergy & immunology': 'allergy-and-immunology',
  'ayurveda': 'ayurvedic-and-unani-medicine',
  'cardiothoracic surgery': 'ctvs',
  'neurosurgery': 'neurosurgeon',
  'dental surgery': 'dentistry',
  'ivf': 'infertility-ivf',
  'infertility': 'infertility-ivf',
  'hair transplant': 'prp-therapy',
  'skin': 'skin-and-beauty',
  'respiratory medicine': 'pulmonology',
};

/// Filters the catalog and ranks matches so title prefixes beat accidental
/// mid-word hits (e.g. "gen" → General Medicine, not Emergency / Urgent).
List<MedicalSpeciality> filterMedicalSpecialities(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return List<MedicalSpeciality>.unmodifiable(
      [...medicalSpecialities]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  final scored = <({MedicalSpeciality speciality, int rank})>[];
  for (final speciality in medicalSpecialities) {
    final rank = _specialityMatchRank(speciality, q);
    if (rank >= 0) {
      scored.add((speciality: speciality, rank: rank));
    }
  }
  scored.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    if (byRank != 0) return byRank;
    return a.speciality.order.compareTo(b.speciality.order);
  });
  return [for (final item in scored) item.speciality];
}

/// Lower is better. `-1` means the speciality should be hidden.
int _specialityMatchRank(MedicalSpeciality speciality, String query) {
  final name = speciality.name.toLowerCase();
  final description = speciality.description.toLowerCase();
  final searchTerm = speciality.searchTerm.toLowerCase();
  final slug = speciality.slug.replaceAll('-', ' ');

  if (name.startsWith(query)) return 0;
  if (_hasWordStartingWith(name, query)) return 1;
  if (searchTerm.startsWith(query)) return 2;
  if (_hasWordStartingWith(searchTerm, query)) return 3;
  if (slug.startsWith(query) || _hasWordStartingWith(slug, query)) return 4;
  if (_hasWordStartingWith(description, query)) return 5;

  // Mid-word fallback only for longer queries so "gen" does not match
  // "Emergency" or "Urgent".
  if (query.length >= 4) {
    if (name.contains(query)) return 6;
    if (searchTerm.contains(query)) return 7;
    if (slug.contains(query)) return 8;
  }
  return -1;
}

bool _hasWordStartingWith(String text, String query) {
  var start = 0;
  while (start <= text.length - query.length) {
    final index = text.indexOf(query, start);
    if (index < 0) return false;
    if (index == 0 || !_isWordChar(text.codeUnitAt(index - 1))) {
      return true;
    }
    start = index + 1;
  }
  return false;
}

bool _isWordChar(int unit) {
  final isDigit = unit >= 48 && unit <= 57;
  final isLower = unit >= 97 && unit <= 122;
  final isUpper = unit >= 65 && unit <= 90;
  return isDigit || isLower || isUpper;
}

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
