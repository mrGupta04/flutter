import '../../../data/models/lab_model.dart';

extension LabModelDisplay on LabModel {
  int get enabledTestCount =>
      offeredTests?.where((t) => t.enabled).length ?? 0;

  int? get startingPriceInr {
    final prices = offeredTests
        ?.where((t) => t.enabled)
        .map((t) => t.discountedPriceInr ?? t.priceInr)
        .toList();
    if (prices == null || prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  int? get maxOriginalPriceInr {
    final prices = offeredTests
        ?.where((t) => t.enabled)
        .map((t) => t.priceInr)
        .toList();
    if (prices == null || prices.isEmpty) return null;
    return prices.reduce((a, b) => a > b ? a : b);
  }

  bool get isNablAccredited {
    final acc = accreditation?.toLowerCase() ?? '';
    return acc.contains('nabl') ||
        (documents?.any(
              (d) =>
                  d.type.toLowerCase().contains('nabl') ||
                  d.label.toLowerCase().contains('nabl'),
            ) ??
            false);
  }

  bool get supportsHomeCollection => homeCollectionAvailable == true;

  bool get supportsLabVisit =>
      offeredTests?.any((t) => t.enabled && t.onsiteCollectionAvailable) ??
      true;

  bool get isOpenNow {
    if (available24x7 == true) return true;
    final hours = operatingHours?.toLowerCase() ?? '';
    if (hours.contains('24') || hours.contains('open 24')) return true;
    // Approximate: treat labs with hours as open during daytime.
    final hour = DateTime.now().hour;
    return hour >= 7 && hour < 21;
  }

  String get openStatusLabel => isOpenNow ? 'Open now' : 'Closed';

  String? get reportDeliverySummary {
    final times = offeredTests
        ?.where((t) => t.enabled && t.reportDeliveryTime != null)
        .map((t) => t.reportDeliveryTime!)
        .toList();
    if (times == null || times.isEmpty) return '24–48 hours';
    return times.first;
  }

  String get fullAddress {
    final parts = [address, city, state, pincode]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toList();
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  double get ratingValue => averageRating ?? 4.5;

  int get reviewsCount => reviewCount ?? 0;
}

extension LabOfferedTestDisplay on LabOfferedTest {
  int get effectivePrice => discountedPriceInr ?? priceInr;

  int? get discountPercent {
    if (discountedPriceInr == null || priceInr <= 0) return null;
    if (discountedPriceInr! >= priceInr) return null;
    return (((priceInr - discountedPriceInr!) / priceInr) * 100).round();
  }
}
