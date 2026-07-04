/// Diagnostic test categories available in the labs catalog.
enum LabTestCategory {
  bloodTests('Blood Tests', 'blood'),
  urineTests('Urine Tests', 'urine'),
  thyroidTests('Thyroid Tests', 'thyroid'),
  diabetesTests('Diabetes Tests', 'diabetes'),
  liverFunctionTests('Liver Function Tests (LFT)', 'lft'),
  kidneyFunctionTests('Kidney Function Tests (KFT)', 'kft'),
  lipidProfile('Lipid Profile', 'lipid'),
  vitaminTests('Vitamin Tests', 'vitamin'),
  hormoneTests('Hormone Tests', 'hormone'),
  allergyTests('Allergy Tests', 'allergy'),
  covid19Tests('COVID-19 Tests', 'covid'),
  fullBodyCheckups('Full Body Checkups', 'checkup'),
  other('Other Investigations', 'other');

  const LabTestCategory(this.label, this.id);

  final String label;
  final String id;
}

/// Sample collection options for a diagnostic test.
enum SampleCollectionOption {
  homeVisit('Home Visit', 'A lab technician visits your location'),
  onsite('Onsite', 'Visit the diagnostic center for sample collection');

  const SampleCollectionOption(this.label, this.description);

  final String label;
  final String description;
}

class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.description,
    required this.priceInr,
    required this.reportDeliveryTime,
    required this.category,
    this.preparationInstructions,
    this.homeVisitAvailable = true,
    this.onsiteAvailable = true,
    this.sampleType = 'Blood',
    this.fastingRequired = false,
    this.originalPriceInr,
    this.discountedPriceInr,
  });

  final String id;
  final String name;
  final String description;
  final int priceInr;
  final String reportDeliveryTime;
  final LabTestCategory category;
  final String? preparationInstructions;
  final bool homeVisitAvailable;
  final bool onsiteAvailable;
  final String sampleType;
  final bool fastingRequired;
  final int? originalPriceInr;
  final int? discountedPriceInr;

  int get effectivePrice => discountedPriceInr ?? priceInr;

  int? get discountPercent {
    final original = originalPriceInr ?? priceInr;
    if (discountedPriceInr == null || original <= 0) return null;
    if (discountedPriceInr! >= original) return null;
    return (((original - discountedPriceInr!) / original) * 100).round();
  }

  bool get requiresFasting =>
      fastingRequired ||
      (preparationInstructions?.toLowerCase().contains('fasting') ?? false);

  List<SampleCollectionOption> get availableCollectionOptions {
    final options = <SampleCollectionOption>[];
    if (homeVisitAvailable) options.add(SampleCollectionOption.homeVisit);
    if (onsiteAvailable) options.add(SampleCollectionOption.onsite);
    return options;
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q) ||
        sampleType.toLowerCase().contains(q);
  }
}
