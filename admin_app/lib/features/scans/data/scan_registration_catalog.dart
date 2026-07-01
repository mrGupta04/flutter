import '../data/models/scan_procedure_model.dart';

/// Templates for scan center registration multi-select.
class ScanRegistrationTemplate {
  const ScanRegistrationTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultDescription,
    this.defaultPreparation,
    this.defaultReportTime = '24 hours',
    this.defaultPrice = 1999,
    this.fastingRequired = false,
    this.homeVisitAvailable = false,
    this.onsiteOnly = true,
    this.prescriptionRequired = true,
  });

  final String id;
  final String name;
  final ScanCategory category;
  final String defaultDescription;
  final String? defaultPreparation;
  final String defaultReportTime;
  final int defaultPrice;
  final bool fastingRequired;
  final bool homeVisitAvailable;
  final bool onsiteOnly;
  final bool prescriptionRequired;
}

class ScanRegistrationCatalog {
  ScanRegistrationCatalog._();

  static const List<ScanCategory> categories = ScanCategory.values;

  static const List<ScanRegistrationTemplate> templates = [
    ScanRegistrationTemplate(
      id: 'mri-brain',
      name: 'MRI Brain',
      category: ScanCategory.mri,
      defaultDescription: 'Brain structure imaging for neurological evaluation.',
      defaultPrice: 5499,
      defaultReportTime: '24–48 hours',
    ),
    ScanRegistrationTemplate(
      id: 'mri-spine',
      name: 'MRI Spine',
      category: ScanCategory.mri,
      defaultDescription: 'Spinal cord and disc evaluation.',
      defaultPrice: 6499,
    ),
    ScanRegistrationTemplate(
      id: 'mri-knee',
      name: 'MRI Knee',
      category: ScanCategory.mri,
      defaultDescription: 'Knee joint and ligament assessment.',
      defaultPrice: 4999,
    ),
    ScanRegistrationTemplate(
      id: 'ct-brain',
      name: 'CT Scan Brain',
      category: ScanCategory.ct,
      defaultDescription: 'Rapid head injury and stroke imaging.',
      defaultPrice: 3499,
    ),
    ScanRegistrationTemplate(
      id: 'ct-chest',
      name: 'CT Scan Chest (HRCT)',
      category: ScanCategory.ct,
      defaultDescription: 'High-resolution lung imaging.',
      defaultPrice: 4499,
    ),
    ScanRegistrationTemplate(
      id: 'ct-abdomen',
      name: 'CT Abdomen & Pelvis',
      category: ScanCategory.ct,
      defaultDescription: 'Abdominal organ evaluation.',
      defaultPrice: 5999,
      fastingRequired: true,
    ),
    ScanRegistrationTemplate(
      id: 'xray-chest',
      name: 'X-Ray Chest',
      category: ScanCategory.xray,
      defaultDescription: 'Chest and lung screening.',
      defaultPrice: 399,
      defaultReportTime: '2–4 hours',
    ),
    ScanRegistrationTemplate(
      id: 'xray-spine',
      name: 'X-Ray Spine',
      category: ScanCategory.xray,
      defaultDescription: 'Spine alignment and fracture screening.',
      defaultPrice: 499,
    ),
    ScanRegistrationTemplate(
      id: 'usg-abdomen',
      name: 'Ultrasound Abdomen',
      category: ScanCategory.ultrasound,
      defaultDescription: 'Abdominal organ ultrasound.',
      defaultPrice: 999,
      fastingRequired: true,
    ),
    ScanRegistrationTemplate(
      id: 'usg-pelvis',
      name: 'Ultrasound Pelvis',
      category: ScanCategory.ultrasound,
      defaultDescription: 'Pelvic organ evaluation.',
      defaultPrice: 899,
    ),
    ScanRegistrationTemplate(
      id: 'pet-whole-body',
      name: 'PET-CT Whole Body',
      category: ScanCategory.pet,
      defaultDescription: 'Metabolic cancer imaging.',
      defaultPrice: 18999,
      fastingRequired: true,
    ),
    ScanRegistrationTemplate(
      id: 'mammography-bilateral',
      name: 'Mammography (Bilateral)',
      category: ScanCategory.mammography,
      defaultDescription: 'Breast cancer screening.',
      defaultPrice: 1999,
    ),
    ScanRegistrationTemplate(
      id: 'ecg-12-lead',
      name: 'ECG (12-Lead)',
      category: ScanCategory.ecg,
      defaultDescription: 'Heart rhythm and electrical activity.',
      defaultPrice: 299,
      defaultReportTime: 'Same day',
      homeVisitAvailable: true,
      onsiteOnly: false,
    ),
    ScanRegistrationTemplate(
      id: 'eeg-routine',
      name: 'EEG (Routine)',
      category: ScanCategory.eeg,
      defaultDescription: 'Brain electrical activity recording.',
      defaultPrice: 2499,
    ),
    ScanRegistrationTemplate(
      id: 'echo-2d',
      name: '2D Echocardiography',
      category: ScanCategory.echo,
      defaultDescription: 'Heart structure and function ultrasound.',
      defaultPrice: 1799,
      homeVisitAvailable: true,
      onsiteOnly: false,
    ),
    ScanRegistrationTemplate(
      id: 'doppler-carotid',
      name: 'Carotid Doppler',
      category: ScanCategory.doppler,
      defaultDescription: 'Neck vessel blood flow assessment.',
      defaultPrice: 1499,
    ),
    ScanRegistrationTemplate(
      id: 'dexa-scan',
      name: 'DEXA Bone Density Scan',
      category: ScanCategory.dexa,
      defaultDescription: 'Osteoporosis screening.',
      defaultPrice: 1499,
    ),
    ScanRegistrationTemplate(
      id: 'fluoroscopy-upper-gi',
      name: 'Fluoroscopy (Upper GI)',
      category: ScanCategory.fluoroscopy,
      defaultDescription: 'Real-time digestive tract imaging.',
      defaultPrice: 2999,
      fastingRequired: true,
    ),
    ScanRegistrationTemplate(
      id: 'endoscopy-upper-gi',
      name: 'Upper GI Endoscopy',
      category: ScanCategory.endoscopy,
      defaultDescription: 'Esophagus and stomach examination.',
      defaultPrice: 3999,
      fastingRequired: true,
    ),
    ScanRegistrationTemplate(
      id: 'colonoscopy',
      name: 'Colonoscopy',
      category: ScanCategory.colonoscopy,
      defaultDescription: 'Large intestine examination.',
      defaultPrice: 5999,
      fastingRequired: true,
    ),
    ScanRegistrationTemplate(
      id: 'bronchoscopy',
      name: 'Bronchoscopy',
      category: ScanCategory.bronchoscopy,
      defaultDescription: 'Airway and lung examination.',
      defaultPrice: 6999,
      fastingRequired: true,
    ),
    ScanRegistrationTemplate(
      id: 'tmt',
      name: 'TMT (Treadmill Test)',
      category: ScanCategory.tmt,
      defaultDescription: 'Cardiac stress evaluation.',
      defaultPrice: 1999,
    ),
    ScanRegistrationTemplate(
      id: 'ncv',
      name: 'NCV (Nerve Conduction)',
      category: ScanCategory.ncv,
      defaultDescription: 'Peripheral nerve function test.',
      defaultPrice: 2499,
    ),
    ScanRegistrationTemplate(
      id: 'emg',
      name: 'EMG',
      category: ScanCategory.emg,
      defaultDescription: 'Muscle electrical activity test.',
      defaultPrice: 2999,
    ),
  ];

  static List<ScanRegistrationTemplate> byCategory(ScanCategory category) {
    return templates.where((t) => t.category == category).toList();
  }
}
