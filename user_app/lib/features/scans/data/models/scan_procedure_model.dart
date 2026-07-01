/// Imaging scan categories for the patient catalog.
enum ScanCategory {
  mri('MRI', 'mri'),
  ct('CT Scan', 'ct'),
  xray('X-Ray', 'xray'),
  ultrasound('Ultrasound', 'ultrasound'),
  pet('PET Scan', 'pet'),
  mammography('Mammography', 'mammography'),
  ecg('ECG', 'ecg'),
  eeg('EEG', 'eeg'),
  echo('2D Echo', 'echo'),
  doppler('Doppler Scan', 'doppler'),
  dexa('DEXA / Bone Density', 'dexa'),
  fluoroscopy('Fluoroscopy', 'fluoroscopy'),
  endoscopy('Endoscopy', 'endoscopy'),
  colonoscopy('Colonoscopy', 'colonoscopy'),
  bronchoscopy('Bronchoscopy', 'bronchoscopy'),
  tmt('TMT (Treadmill Test)', 'tmt'),
  ncv('NCV', 'ncv'),
  emg('EMG', 'emg'),
  other('Other Imaging', 'other');

  const ScanCategory(this.label, this.id);

  final String label;
  final String id;
}

enum ScanReportFormat {
  digital('Digital'),
  pdf('PDF'),
  printed('Printed');

  const ScanReportFormat(this.label);
  final String label;

  static ScanReportFormat fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pdf':
        return ScanReportFormat.pdf;
      case 'printed':
        return ScanReportFormat.printed;
      default:
        return ScanReportFormat.digital;
    }
  }
}

enum ScanAvailabilityStatus {
  available('Available'),
  limited('Limited slots'),
  unavailable('Unavailable');

  const ScanAvailabilityStatus(this.label);
  final String label;

  static ScanAvailabilityStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'limited':
        return ScanAvailabilityStatus.limited;
      case 'unavailable':
        return ScanAvailabilityStatus.unavailable;
      default:
        return ScanAvailabilityStatus.available;
    }
  }
}

class ScanProcedure {
  const ScanProcedure({
    required this.id,
    required this.name,
    required this.description,
    required this.priceInr,
    required this.reportDeliveryTime,
    required this.category,
    this.discountedPriceInr,
    this.preparationInstructions,
    this.fastingRequired = false,
    this.homeVisitAvailable = false,
    this.onsiteOnly = true,
    this.reportFormat = ScanReportFormat.digital,
    this.availabilityStatus = ScanAvailabilityStatus.available,
    this.prescriptionRequired = true,
    this.images = const [],
  });

  final String id;
  final String name;
  final String description;
  final int priceInr;
  final int? discountedPriceInr;
  final String reportDeliveryTime;
  final ScanCategory category;
  final String? preparationInstructions;
  final bool fastingRequired;
  final bool homeVisitAvailable;
  final bool onsiteOnly;
  final ScanReportFormat reportFormat;
  final ScanAvailabilityStatus availabilityStatus;
  final bool prescriptionRequired;
  final List<String> images;

  int get effectivePrice => discountedPriceInr ?? priceInr;

  bool get hasDiscount =>
      discountedPriceInr != null && discountedPriceInr! < priceInr;

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q);
  }
}
