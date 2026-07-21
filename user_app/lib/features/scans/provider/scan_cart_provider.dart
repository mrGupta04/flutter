import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/scan_center_model.dart';

class ScanCartItem {
  const ScanCartItem({
    required this.scanId,
    required this.scanName,
    required this.categoryId,
    required this.priceInr,
    this.originalPriceInr,
    this.reportDeliveryTime,
    this.prescriptionRequired = true,
    this.preparationInstructions,
  });

  final String scanId;
  final String scanName;
  final String categoryId;
  final int priceInr;
  final int? originalPriceInr;
  final String? reportDeliveryTime;
  final bool prescriptionRequired;
  final String? preparationInstructions;

  factory ScanCartItem.fromOffered(ScanOfferedProcedure scan) {
    return ScanCartItem(
      scanId: scan.scanId,
      scanName: scan.scanName,
      categoryId: scan.categoryId,
      priceInr: scan.effectivePrice,
      originalPriceInr: scan.priceInr,
      reportDeliveryTime: scan.reportDeliveryTime,
      prescriptionRequired: scan.prescriptionRequired,
      preparationInstructions: scan.preparationInstructions,
    );
  }
}

class ScanCartState {
  const ScanCartState({
    this.centerId,
    this.centerName,
    this.items = const [],
  });

  final String? centerId;
  final String? centerName;
  final List<ScanCartItem> items;

  int get itemCount => items.length;

  int get subtotal => items.fold(0, (sum, item) => sum + item.priceInr);

  int get originalTotal => items.fold(0, (sum, item) {
        return sum + (item.originalPriceInr ?? item.priceInr);
      });

  int get discount => originalTotal - subtotal;

  bool contains(String scanId) => items.any((i) => i.scanId == scanId);

  ScanCartState copyWith({
    String? centerId,
    String? centerName,
    List<ScanCartItem>? items,
    bool clearCenter = false,
  }) {
    return ScanCartState(
      centerId: clearCenter ? null : (centerId ?? this.centerId),
      centerName: clearCenter ? null : (centerName ?? this.centerName),
      items: items ?? this.items,
    );
  }
}

class ScanCartNotifier extends StateNotifier<ScanCartState> {
  ScanCartNotifier() : super(const ScanCartState());

  bool addItem({
    required ScanCenterModel center,
    required ScanCartItem item,
  }) {
    final centerId = center.id;
    if (centerId == null || centerId.isEmpty) return false;

    if (state.centerId != null &&
        state.centerId != centerId &&
        state.items.isNotEmpty) {
      return false;
    }
    if (state.contains(item.scanId)) return true;

    state = ScanCartState(
      centerId: centerId,
      centerName: center.displayName,
      items: [...state.items, item],
    );
    return true;
  }

  void removeItem(String scanId) {
    final next = state.items.where((i) => i.scanId != scanId).toList();
    if (next.isEmpty) {
      state = const ScanCartState();
    } else {
      state = state.copyWith(items: next);
    }
  }

  void clear() => state = const ScanCartState();

  void replaceCenterCart({
    required ScanCenterModel center,
    required List<ScanCartItem> items,
  }) {
    state = ScanCartState(
      centerId: center.id,
      centerName: center.displayName,
      items: items,
    );
  }
}

final scanCartProvider =
    StateNotifierProvider<ScanCartNotifier, ScanCartState>((ref) {
  return ScanCartNotifier();
});
