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
    this.includedTestsLabel,
    this.parameterCount,
    this.highlightText,
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

  /// Short list of included markers, e.g. "TSH, T3, T4".
  final String? includedTestsLabel;

  /// Number of parameters / tests in the panel.
  final int? parameterCount;

  /// One-line benefit shown in the card footer.
  final String? highlightText;

  int get effectivePrice => discountedPriceInr ?? priceInr;

  /// MRP shown on cards. Uses catalog MRP when set; otherwise a list price
  /// so marketplace-style discount UI can render consistently.
  int get displayOriginalPrice {
    if (originalPriceInr != null) return originalPriceInr!;
    final suggested = (effectivePrice / 0.54);
    final rounded = ((suggested / 50).ceil() * 50);
    return rounded <= effectivePrice ? effectivePrice + 50 : rounded;
  }

  int? get discountPercent {
    final original = displayOriginalPrice;
    final sale = effectivePrice;
    if (original <= 0 || sale >= original) return null;
    return (((original - sale) / original) * 100).round();
  }

  bool get hasCouponPricing =>
      discountPercent != null && discountPercent! > 0;

  String get subtitleLabel {
    if (includedTestsLabel != null && includedTestsLabel!.isNotEmpty) {
      return includedTestsLabel!;
    }
    final paren = RegExp(r'\(([^)]+)\)').firstMatch(name);
    if (paren != null) return paren.group(1)!;
    return sampleType;
  }

  String get testsCountLabel {
    final count = parameterCount ?? 1;
    return '$count ${count == 1 ? 'TEST' : 'TESTS'}';
  }

  String get reportTimeCompact {
    final digits = RegExp(r'(\d+)').allMatches(reportDeliveryTime).toList();
    if (digits.isEmpty) return reportDeliveryTime.toUpperCase();
    final hours = digits.last.group(1)!;
    final lower = reportDeliveryTime.toLowerCase();
    if (lower.contains('day')) return '$hours DAYS';
    return '$hours HRS';
  }

  String get footerHighlight => highlightText ?? description;

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
        sampleType.toLowerCase().contains(q) ||
        (includedTestsLabel?.toLowerCase().contains(q) ?? false);
  }
}
