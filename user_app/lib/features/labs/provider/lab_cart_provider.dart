import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';

class LabCartItem {
  const LabCartItem({
    required this.testId,
    required this.testName,
    required this.priceInr,
    this.originalPriceInr,
    this.reportDeliveryTime,
    this.homeCollectionAvailable = true,
    this.onsiteCollectionAvailable = true,
  });

  final String testId;
  final String testName;
  final int priceInr;
  final int? originalPriceInr;
  final String? reportDeliveryTime;
  final bool homeCollectionAvailable;
  final bool onsiteCollectionAvailable;

  factory LabCartItem.fromOfferedTest(LabOfferedTest test) {
    return LabCartItem(
      testId: test.testId,
      testName: test.testName,
      priceInr: test.discountedPriceInr ?? test.priceInr,
      originalPriceInr: test.priceInr,
      reportDeliveryTime: test.reportDeliveryTime,
      homeCollectionAvailable: test.homeCollectionAvailable,
      onsiteCollectionAvailable: test.onsiteCollectionAvailable,
    );
  }
}

class LabCartState {
  const LabCartState({
    this.labId,
    this.labName,
    this.items = const [],
  });

  final String? labId;
  final String? labName;
  final List<LabCartItem> items;

  int get itemCount => items.length;

  int get subtotal =>
      items.fold(0, (sum, item) => sum + item.priceInr);

  int get originalTotal => items.fold(0, (sum, item) {
        return sum + (item.originalPriceInr ?? item.priceInr);
      });

  int get discount => originalTotal - subtotal;

  bool contains(String testId) => items.any((i) => i.testId == testId);

  LabCartState copyWith({
    String? labId,
    String? labName,
    List<LabCartItem>? items,
    bool clearLab = false,
  }) {
    return LabCartState(
      labId: clearLab ? null : (labId ?? this.labId),
      labName: clearLab ? null : (labName ?? this.labName),
      items: items ?? this.items,
    );
  }
}

class LabCartNotifier extends StateNotifier<LabCartState> {
  LabCartNotifier() : super(const LabCartState());

  bool addItem({
    required LabModel lab,
    required LabCartItem item,
  }) {
    if (state.labId != null &&
        state.labId != lab.id &&
        state.items.isNotEmpty) {
      return false;
    }
    if (state.contains(item.testId)) return true;

    state = LabCartState(
      labId: lab.id,
      labName: lab.displayName,
      items: [...state.items, item],
    );
    return true;
  }

  void removeItem(String testId) {
    final next = state.items.where((i) => i.testId != testId).toList();
    if (next.isEmpty) {
      state = const LabCartState();
    } else {
      state = state.copyWith(items: next);
    }
  }

  void clear() => state = const LabCartState();

  void replaceLabCart({
    required LabModel lab,
    required List<LabCartItem> items,
  }) {
    state = LabCartState(
      labId: lab.id,
      labName: lab.displayName,
      items: items,
    );
  }
}

final labCartProvider =
    StateNotifierProvider<LabCartNotifier, LabCartState>((ref) {
  return LabCartNotifier();
});
