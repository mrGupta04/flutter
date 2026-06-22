import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookable_slot_model.dart';
import '../../../data/models/doctor_model.dart';
import '../../../data/models/previous_report_model.dart';
import '../../../data/repositories/online_consult_repository.dart';

import '../../../data/services/booking_payment_flow.dart';

import '../../../data/repositories/doctor_registration_repository.dart';

final onlineConsultRepositoryProvider = Provider(
  (ref) => OnlineConsultRepository(),
);

final bookingPaymentFlowProvider = Provider.autoDispose((ref) {
  final flow = BookingPaymentFlow();
  ref.onDispose(flow.dispose);
  return flow;
});

final doctorForBookingProvider =
    FutureProvider.family<DoctorModel, String>((ref, doctorId) async {
  final repo = DoctorRegistrationRepository();
  final res = await repo.getDoctorProfile(doctorId: doctorId);
  if (!res.success || res.data == null) {
    throw Exception(res.error ?? 'Doctor not found');
  }
  return res.data!;
});

final bookableSlotsProvider =
    FutureProvider.family<BookableSlotsResponse, BookableSlotsQuery>((ref, query) async {
  final repo = ref.watch(onlineConsultRepositoryProvider);
  final res = await repo.getBookableSlots(
    doctorId: query.doctorId,
    consultationType: query.consultationType,
  );
  if (!res.success || res.data == null) {
    throw Exception(res.error ?? 'Could not load available slots');
  }
  return res.data!;
});

class BookableSlotsQuery {
  const BookableSlotsQuery({
    required this.doctorId,
    this.consultationType = 'online_consult',
  });

  final String doctorId;
  final String consultationType;

  @override
  bool operator ==(Object other) {
    return other is BookableSlotsQuery &&
        other.doctorId == doctorId &&
        other.consultationType == consultationType;
  }

  @override
  int get hashCode => Object.hash(doctorId, consultationType);
}

class OnlineConsultBookingState {
  const OnlineConsultBookingState({
    this.selectedSlot,
    this.slotHoldId,
    this.isReservingSlot = false,
    this.pendingReports = const [],
    this.isSubmitting = false,
    this.error,
    this.booking,
  });

  final BookableSlot? selectedSlot;
  final String? slotHoldId;
  final bool isReservingSlot;
  final List<PendingPreviousReport> pendingReports;
  final bool isSubmitting;
  final String? error;
  final ConsultationBookingResult? booking;

  OnlineConsultBookingState copyWith({
    BookableSlot? selectedSlot,
    String? slotHoldId,
    bool? isReservingSlot,
    List<PendingPreviousReport>? pendingReports,
    bool? isSubmitting,
    String? error,
    ConsultationBookingResult? booking,
    bool clearSlot = false,
    bool clearHold = false,
  }) {
    return OnlineConsultBookingState(
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      slotHoldId: clearHold ? null : (slotHoldId ?? this.slotHoldId),
      isReservingSlot: isReservingSlot ?? this.isReservingSlot,
      pendingReports: pendingReports ?? this.pendingReports,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      booking: booking ?? this.booking,
    );
  }
}

class OnlineConsultBookingNotifier extends StateNotifier<OnlineConsultBookingState> {
  OnlineConsultBookingNotifier(
    this._paymentFlow,
    this._repository,
    this._doctorId,
  ) : super(const OnlineConsultBookingState());

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
      consultationType: 'online_consult',
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

  void setPendingReports(List<PendingPreviousReport> reports) {
    state = state.copyWith(pendingReports: reports, error: null);
  }

  Future<bool> submit({
    required String doctorId,
    required String patientName,
    required String patientMobile,
    String? patientEmail,
    String? patientNotes,
  }) async {
    final slot = state.selectedSlot;
    if (slot == null) {
      state = state.copyWith(error: 'Please select a time slot');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final booking = await _paymentFlow.payAndConfirm(
        doctorId: doctorId,
        consultationType: 'online_consult',
        slot: slot,
        patientName: patientName,
        patientMobile: patientMobile,
        patientEmail: patientEmail,
        patientNotes: patientNotes,
        previousReports: state.pendingReports,
      );
      if (booking != null) {
        state = OnlineConsultBookingState(booking: booking);
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

  void reset() {
    state = const OnlineConsultBookingState();
  }
}

final onlineConsultBookingProvider = StateNotifierProvider.autoDispose
    .family<OnlineConsultBookingNotifier, OnlineConsultBookingState, String>(
  (ref, doctorId) {
    final notifier = OnlineConsultBookingNotifier(
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
