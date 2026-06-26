import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookable_slot_model.dart';
import '../../../data/repositories/online_consult_repository.dart';
import '../../../data/services/booking_payment_flow.dart';
import '../../online_consult/provider/online_consult_provider.dart';

final bookableSlotsForHomeVisitProvider =
    FutureProvider.family<BookableSlotsResponse, String>((ref, doctorId) async {
  return ref.watch(
    bookableSlotsProvider(
      BookableSlotsQuery(doctorId: doctorId, consultationType: 'book_home'),
    ).future,
  );
});

class HomeVisitBookingState {
  const HomeVisitBookingState({
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

  HomeVisitBookingState copyWith({
    BookableSlot? selectedSlot,
    String? slotHoldId,
    bool? isReservingSlot,
    bool? isSubmitting,
    String? error,
    ConsultationBookingResult? booking,
    bool clearSlot = false,
    bool clearHold = false,
  }) {
    return HomeVisitBookingState(
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      slotHoldId: clearHold ? null : (slotHoldId ?? this.slotHoldId),
      isReservingSlot: isReservingSlot ?? this.isReservingSlot,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      booking: booking ?? this.booking,
    );
  }
}

class HomeVisitBookingNotifier extends StateNotifier<HomeVisitBookingState> {
  HomeVisitBookingNotifier(
    this._paymentFlow,
    this._repository,
    this._doctorId,
  ) : super(const HomeVisitBookingState());

  final BookingPaymentFlow _paymentFlow;
  final OnlineConsultRepository _repository;
  final String _doctorId;

  Future<void> selectSlot(BookableSlot? slot) async {
    if (slot == null) {
      await releaseHold();
      state = state.copyWith(clearSlot: true, clearHold: true, error: null);
      return;
    }

    state = state.copyWith(isReservingSlot: true, error: null);
    final response = await _repository.holdSlot(
      doctorId: _doctorId,
      consultationType: 'book_home',
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
    required String doctorId,
    required String patientName,
    required String patientMobile,
    required String patientAddress,
    required String patientCity,
    required String patientPincode,
    String? patientEmail,
    String? patientState,
    String? visitReason,
    String? patientNotes,
  }) async {
    final slot = state.selectedSlot;
    if (slot == null) {
      state = state.copyWith(error: 'Please select an appointment time');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final booking = await _paymentFlow.payAndConfirm(
        doctorId: doctorId,
        consultationType: 'book_home',
        slot: slot,
        patientName: patientName,
        patientMobile: patientMobile,
        patientEmail: patientEmail,
        patientNotes: patientNotes,
        patientAddress: patientAddress,
        patientCity: patientCity,
        patientState: patientState,
        patientPincode: patientPincode,
        visitReason: visitReason,
      );
      if (booking != null) {
        state = HomeVisitBookingState(booking: booking);
        return true;
      }

      state = state.copyWith(
        isSubmitting: false,
        error: 'Booking failed',
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

final homeVisitBookingProvider = StateNotifierProvider.autoDispose
    .family<HomeVisitBookingNotifier, HomeVisitBookingState, String>(
  (ref, doctorId) {
    final notifier = HomeVisitBookingNotifier(
      ref.watch(bookingPaymentFlowProvider),
      ref.watch(onlineConsultRepositoryProvider),
      doctorId,
    );
    ref.onDispose(() {
      notifier.releaseHold();
    });
    return notifier;
  },
);
