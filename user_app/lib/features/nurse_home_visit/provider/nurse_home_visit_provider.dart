import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bookable_slot_model.dart';
import '../../../data/repositories/nurse_home_visit_repository.dart';

final nurseHomeVisitRepositoryProvider = Provider(
  (ref) => NurseHomeVisitRepository(),
);

final nurseBookableSlotsProvider =
    FutureProvider.family<BookableSlotsResponse, String>((ref, nurseId) async {
  final repo = ref.watch(nurseHomeVisitRepositoryProvider);
  final res = await repo.getBookableSlots(nurseId: nurseId);
  if (!res.success || res.data == null) {
    throw Exception(res.error ?? 'Could not load available slots');
  }
  return res.data!;
});

class NurseHomeVisitBookingState {
  const NurseHomeVisitBookingState({
    this.selectedSlot,
    this.slotHoldId,
    this.isReservingSlot = false,
    this.isSubmitting = false,
    this.error,
    this.booking,
  });

  final BookableSlot? selectedSlot;
  final String? slotHoldId;
  final bool isReservingSlot;
  final bool isSubmitting;
  final String? error;
  final ConsultationBookingResult? booking;

  NurseHomeVisitBookingState copyWith({
    BookableSlot? selectedSlot,
    String? slotHoldId,
    bool? isReservingSlot,
    bool? isSubmitting,
    String? error,
    ConsultationBookingResult? booking,
    bool clearSlot = false,
    bool clearHold = false,
  }) {
    return NurseHomeVisitBookingState(
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      slotHoldId: clearHold ? null : (slotHoldId ?? this.slotHoldId),
      isReservingSlot: isReservingSlot ?? this.isReservingSlot,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      booking: booking ?? this.booking,
    );
  }
}

class NurseHomeVisitBookingNotifier
    extends StateNotifier<NurseHomeVisitBookingState> {
  NurseHomeVisitBookingNotifier(this._repository, this._nurseId)
      : super(const NurseHomeVisitBookingState());

  final NurseHomeVisitRepository _repository;
  final String _nurseId;

  Future<void> selectSlot(BookableSlot? slot) async {
    if (slot == null) {
      await releaseHold();
      state = state.copyWith(clearSlot: true, clearHold: true, error: null);
      return;
    }

    state = state.copyWith(isReservingSlot: true, error: null);
    final response = await _repository.holdSlot(
      nurseId: _nurseId,
      dayOfWeek: slot.dayOfWeek,
      startHour: slot.startHour,
      slotStart: slot.slotStart,
      holdId: state.slotHoldId,
    );

    if (!response.success || response.data == null) {
      state = state.copyWith(
        isReservingSlot: false,
        clearSlot: true,
        clearHold: true,
        error: response.error ?? 'This slot is no longer available',
      );
      return;
    }

    state = state.copyWith(
      selectedSlot: slot,
      slotHoldId: response.data!.holdId,
      isReservingSlot: false,
      error: null,
    );
  }

  Future<void> releaseHold() async {
    final holdId = state.slotHoldId;
    if (holdId == null || holdId.isEmpty) return;
    await _repository.releaseSlotHold(holdId: holdId);
    state = state.copyWith(clearHold: true);
  }

  Future<bool> submit({
    required String patientName,
    required String patientMobile,
    required String patientAddress,
    required String patientCity,
    required String patientPincode,
    String? patientEmail,
    String? patientState,
    String? visitReason,
    double? patientLatitude,
    double? patientLongitude,
    String? couponCode,
  }) async {
    final slot = state.selectedSlot;
    if (slot == null) {
      state = state.copyWith(error: 'Please select an appointment time');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final response = await _repository.requestHomeVisit(
        nurseId: _nurseId,
        patientName: patientName,
        patientMobile: patientMobile,
        patientEmail: patientEmail,
        patientAddress: patientAddress,
        patientCity: patientCity,
        patientState: patientState,
        patientPincode: patientPincode,
        visitReason: visitReason,
        patientLatitude: patientLatitude,
        patientLongitude: patientLongitude,
        couponCode: couponCode,
        dayOfWeek: slot.dayOfWeek,
        startHour: slot.startHour,
        slotStart: slot.slotStart,
      );

      if (response.success && response.data != null) {
        state = NurseHomeVisitBookingState(booking: response.data);
        return true;
      }

      state = state.copyWith(
        isSubmitting: false,
        error: response.error ?? 'Request failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final nurseHomeVisitBookingProvider = StateNotifierProvider.autoDispose
    .family<NurseHomeVisitBookingNotifier, NurseHomeVisitBookingState, String>(
  (ref, nurseId) {
    final notifier = NurseHomeVisitBookingNotifier(
      ref.watch(nurseHomeVisitRepositoryProvider),
      nurseId,
    );
    ref.onDispose(() {
      notifier.releaseHold();
    });
    return notifier;
  },
);
