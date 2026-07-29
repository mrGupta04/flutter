import '../../../data/models/scan_center_model.dart';
import 'models/scan_procedure_model.dart';

/// Maps API `categoryId` values onto patient-facing [ScanCategory] chips.
ScanCategory scanCategoryFromId(String? id) {
  if (id == null || id.trim().isEmpty) return ScanCategory.other;
  final lower = id.trim().toLowerCase();

  for (final category in ScanCategory.values) {
    if (category.id == lower) return category;
  }

  if (lower.contains('mri')) return ScanCategory.mri;
  if (lower.contains('ct') || lower.contains('hrct')) return ScanCategory.ct;
  if (lower.contains('xray') || lower.contains('x-ray') || lower.contains('opg')) {
    return ScanCategory.xray;
  }
  if (lower.contains('ultrasound') || lower.contains('usg') || lower.contains('sono')) {
    return ScanCategory.ultrasound;
  }
  if (lower.contains('pet')) return ScanCategory.pet;
  if (lower.contains('mammo')) return ScanCategory.mammography;
  if (lower.contains('ecg') || lower.contains('ekg')) return ScanCategory.ecg;
  if (lower.contains('eeg')) return ScanCategory.eeg;
  if (lower.contains('echo')) return ScanCategory.echo;
  if (lower.contains('doppler')) return ScanCategory.doppler;
  if (lower.contains('dexa') || lower.contains('bone')) return ScanCategory.dexa;
  if (lower.contains('fluoro')) return ScanCategory.fluoroscopy;
  if (lower.contains('endoscop')) return ScanCategory.endoscopy;
  if (lower.contains('colonoscop')) return ScanCategory.colonoscopy;
  if (lower.contains('bronchoscop')) return ScanCategory.bronchoscopy;
  if (lower.contains('tmt') || lower.contains('treadmill')) return ScanCategory.tmt;
  if (lower.contains('ncv')) return ScanCategory.ncv;
  if (lower.contains('emg')) return ScanCategory.emg;
  return ScanCategory.other;
}

ScanProcedure scanProcedureFromOffered(ScanOfferedProcedure offered) {
  return ScanProcedure(
    id: offered.scanId,
    name: offered.scanName,
    description: offered.description ?? '',
    priceInr: offered.priceInr,
    discountedPriceInr: offered.discountedPriceInr,
    reportDeliveryTime: offered.reportDeliveryTime ?? '24–48 hours',
    category: scanCategoryFromId(offered.categoryId),
    preparationInstructions: offered.preparationInstructions,
    fastingRequired: offered.fastingRequired,
    homeVisitAvailable: offered.homeVisitAvailable,
    onsiteOnly: offered.onsiteOnly,
    reportFormat: ScanReportFormat.fromString(offered.reportFormat),
    availabilityStatus:
        ScanAvailabilityStatus.fromString(offered.availabilityStatus),
    prescriptionRequired: offered.prescriptionRequired,
    images: offered.images,
  );
}

/// Helpers for filtering/grouping scan procedures loaded from the API.
class ScansCatalog {
  ScansCatalog._();

  static const List<ScanCategory> allCategories = ScanCategory.values;

  /// Dedupes offered scans across centers (keeps the lowest effective price).
  static List<ScanProcedure> fromCenters(List<ScanCenterModel> centers) {
    final byId = <String, ScanProcedure>{};
    for (final center in centers) {
      for (final offered in center.offeredScans ?? const <ScanOfferedProcedure>[]) {
        if (!offered.enabled || offered.scanId.trim().isEmpty) continue;
        final procedure = scanProcedureFromOffered(offered);
        final existing = byId[procedure.id];
        if (existing == null ||
            procedure.effectivePrice < existing.effectivePrice) {
          byId[procedure.id] = procedure;
        }
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static List<ScanProcedure> filter(
    List<ScanProcedure> procedures, {
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

  static ScanProcedure? byId(List<ScanProcedure> procedures, String id) {
    for (final scan in procedures) {
      if (scan.id == id) return scan;
    }
    return null;
  }
}
