import 'models/scan_procedure_model.dart';

/// Static catalog of imaging scans grouped by category.
class ScansCatalog {
  ScansCatalog._();

  static const List<ScanCategory> allCategories = ScanCategory.values;

  static const List<ScanProcedure> procedures = [
    // MRI
    ScanProcedure(
      id: 'mri-brain',
      name: 'MRI Brain',
      description: 'Detailed imaging of brain structures for headaches, seizures, or stroke evaluation.',
      priceInr: 5499,
      reportDeliveryTime: '24–48 hours',
      category: ScanCategory.mri,
      preparationInstructions: 'Remove all metal objects; inform about implants or pacemaker.',
    ),
    ScanProcedure(
      id: 'mri-spine',
      name: 'MRI Spine (Cervical / Lumbar)',
      description: 'Evaluates disc herniation, nerve compression, and spinal cord conditions.',
      priceInr: 6499,
      reportDeliveryTime: '24–48 hours',
      category: ScanCategory.mri,
      preparationInstructions: 'No fasting required; wear comfortable clothing without metal.',
    ),
    ScanProcedure(
      id: 'mri-knee',
      name: 'MRI Knee',
      description: 'Assesses ligament tears, meniscus injury, and joint damage.',
      priceInr: 4999,
      reportDeliveryTime: '24 hours',
      category: ScanCategory.mri,
    ),
    ScanProcedure(
      id: 'mri-abdomen',
      name: 'MRI Abdomen',
      description: 'Detailed imaging of liver, pancreas, kidneys, and abdominal organs.',
      priceInr: 7999,
      reportDeliveryTime: '48 hours',
      category: ScanCategory.mri,
      preparationInstructions: 'Fasting 4–6 hours may be required; follow center instructions.',
    ),

    // X-Ray
    ScanProcedure(
      id: 'xray-chest',
      name: 'X-Ray Chest (PA View)',
      description: 'Screens lungs, heart size, and rib cage for infection or injury.',
      priceInr: 399,
      reportDeliveryTime: '2–4 hours',
      category: ScanCategory.xray,
    ),
    ScanProcedure(
      id: 'xray-spine',
      name: 'X-Ray Spine',
      description: 'Evaluates vertebral alignment, fractures, and degenerative changes.',
      priceInr: 499,
      reportDeliveryTime: '2–4 hours',
      category: ScanCategory.xray,
    ),
    ScanProcedure(
      id: 'xray-knee',
      name: 'X-Ray Knee (AP / Lateral)',
      description: 'Initial assessment of knee joint, bones, and arthritis.',
      priceInr: 349,
      reportDeliveryTime: '2–4 hours',
      category: ScanCategory.xray,
    ),
    ScanProcedure(
      id: 'xray-dental',
      name: 'Dental X-Ray (OPG)',
      description: 'Panoramic view of teeth, jaws, and surrounding bone.',
      priceInr: 599,
      reportDeliveryTime: 'Same day',
      category: ScanCategory.xray,
    ),

    // CT Scan
    ScanProcedure(
      id: 'ct-brain',
      name: 'CT Scan Brain',
      description: 'Rapid imaging for head injury, bleeding, or stroke evaluation.',
      priceInr: 3499,
      reportDeliveryTime: '12–24 hours',
      category: ScanCategory.ct,
    ),
    ScanProcedure(
      id: 'ct-chest',
      name: 'CT Scan Chest (HRCT)',
      description: 'High-resolution lung imaging for infection, fibrosis, or nodules.',
      priceInr: 4499,
      reportDeliveryTime: '12–24 hours',
      category: ScanCategory.ct,
    ),
    ScanProcedure(
      id: 'ct-abdomen',
      name: 'CT Scan Abdomen & Pelvis',
      description: 'Comprehensive abdominal organ evaluation with contrast option.',
      priceInr: 5999,
      reportDeliveryTime: '24 hours',
      category: ScanCategory.ct,
      preparationInstructions: 'Fasting 4–6 hours; kidney function test may be required for contrast.',
    ),

    // Ultrasound
    ScanProcedure(
      id: 'usg-abdomen',
      name: 'Ultrasound Abdomen',
      description: 'Non-invasive imaging of liver, gallbladder, kidneys, and spleen.',
      priceInr: 999,
      reportDeliveryTime: '4–6 hours',
      category: ScanCategory.ultrasound,
      preparationInstructions: 'Fasting 6–8 hours; drink water for bladder if pelvic included.',
    ),
    ScanProcedure(
      id: 'usg-pelvis',
      name: 'Ultrasound Pelvis',
      description: 'Evaluates uterus, ovaries, bladder, and pelvic organs.',
      priceInr: 899,
      reportDeliveryTime: '4–6 hours',
      category: ScanCategory.ultrasound,
      preparationInstructions: 'Full bladder required; drink 4–5 glasses of water 1 hour before.',
    ),
    ScanProcedure(
      id: 'usg-thyroid',
      name: 'Ultrasound Thyroid',
      description: 'Assesses thyroid nodules, goitre, and neck lymph nodes.',
      priceInr: 799,
      reportDeliveryTime: '4–6 hours',
      category: ScanCategory.ultrasound,
    ),
    ScanProcedure(
      id: 'usg-pregnancy',
      name: 'Obstetric Ultrasound (Anomaly Scan)',
      description: 'Fetal growth monitoring and structural anomaly screening.',
      priceInr: 1499,
      reportDeliveryTime: 'Same day',
      category: ScanCategory.ultrasound,
      preparationInstructions: 'Carry previous pregnancy records and doctor referral.',
    ),

    // PET Scan
    ScanProcedure(
      id: 'pet-whole-body',
      name: 'PET-CT Whole Body',
      description: 'Cancer staging, recurrence monitoring, and metabolic imaging.',
      priceInr: 18999,
      reportDeliveryTime: '48–72 hours',
      category: ScanCategory.pet,
      preparationInstructions: 'Fasting 6 hours; avoid strenuous exercise 24 hours prior.',
    ),

    // Mammography
    ScanProcedure(
      id: 'mammography-bilateral',
      name: 'Mammography (Bilateral)',
      description: 'Breast cancer screening for women aged 40 and above.',
      priceInr: 1999,
      reportDeliveryTime: '24 hours',
      category: ScanCategory.mammography,
      preparationInstructions: 'Avoid deodorant, powder, or lotion on chest area.',
    ),

    // Other
    ScanProcedure(
      id: 'dexa-scan',
      name: 'DEXA Bone Density Scan',
      description: 'Measures bone mineral density for osteoporosis screening.',
      priceInr: 1499,
      reportDeliveryTime: 'Same day',
      category: ScanCategory.other,
    ),
    ScanProcedure(
      id: 'echo-2d',
      name: '2D Echocardiography',
      description: 'Ultrasound of heart structure and function.',
      priceInr: 1799,
      reportDeliveryTime: 'Same day',
      category: ScanCategory.other,
    ),
  ];

  static List<ScanProcedure> filter({
    String? query,
    ScanCategory? category,
  }) {
    return procedures.where((scan) {
      if (category != null && scan.category != category) return false;
      if (query != null && query.isNotEmpty && !scan.matchesQuery(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  static Map<ScanCategory, List<ScanProcedure>> groupedByCategory(
    List<ScanProcedure> filtered,
  ) {
    final map = <ScanCategory, List<ScanProcedure>>{};
    for (final scan in filtered) {
      map.putIfAbsent(scan.category, () => []).add(scan);
    }
    return map;
  }
}
