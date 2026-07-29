import '../../../data/models/scan_center_model.dart';

extension ScanCenterModelDisplay on ScanCenterModel {
  int get enabledScanCount =>
      offeredScans?.where((s) => s.enabled).length ?? 0;

  int? get startingPriceInr {
    final prices = offeredScans
        ?.where((s) => s.enabled)
        .map((s) => s.discountedPriceInr ?? s.priceInr)
        .toList();
    if (prices == null || prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  int? get maxOriginalPriceInr {
    final prices =
        offeredScans?.where((s) => s.enabled).map((s) => s.priceInr).toList();
    if (prices == null || prices.isEmpty) return null;
    return prices.reduce((a, b) => a > b ? a : b);
  }

  bool get hasActiveOfferBadge => activeOffer != null;

  bool get supportsHomeVisit =>
      homeVisitAvailable == true ||
      (offeredScans?.any((s) => s.enabled && s.homeVisitAvailable) ?? false);

  bool get supportsCenterVisit =>
      offeredScans?.any((s) => s.enabled) ?? true;

  bool get isOpenNow {
    if (available24x7 == true) return true;
    final hours = operatingHours?.toLowerCase() ?? '';
    if (hours.contains('24') || hours.contains('open 24')) return true;
    final hour = DateTime.now().hour;
    return hour >= 7 && hour < 21;
  }

  String get openStatusLabel => isOpenNow ? 'Open now' : 'Closed';

  String? get reportDeliverySummary {
    final times = offeredScans
        ?.where((s) => s.enabled && s.reportDeliveryTime != null)
        .map((s) => s.reportDeliveryTime!)
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

extension ScanOfferedProcedureDisplay on ScanOfferedProcedure {
  int get displayEffectivePrice => discountedPriceInr ?? priceInr;

  int? get discountPercent {
    if (discountedPriceInr == null || priceInr <= 0) return null;
    if (discountedPriceInr! >= priceInr) return null;
    return (((priceInr - discountedPriceInr!) / priceInr) * 100).round();
  }
}
