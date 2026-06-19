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
    FutureProvider.family<BookableSlotsResponse, String>((ref, doctorId) async {
  final repo = ref.watch(onlineConsultRepositoryProvider);
  final res = await repo.getBookableSlots(doctorId: doctorId);
  if (!res.success || res.data == null) {
    throw Exception(res.error ?? 'Could not load available slots');
  }
  return res.data!;
});

class OnlineConsultBookingState {
  const OnlineConsultBookingState({
    this.selectedSlot,
    this.pendingReports = const [],
    this.isSubmitting = false,
    this.error,
    this.booking,
  });

  final BookableSlot? selectedSlot;
  final List<PendingPreviousReport> pendingReports;
  final bool isSubmitting;
  final String? error;
  final ConsultationBookingResult? booking;

  OnlineConsultBookingState copyWith({
    BookableSlot? selectedSlot,
    List<PendingPreviousReport>? pendingReports,
    bool? isSubmitting,
    String? error,
    ConsultationBookingResult? booking,
    bool clearSlot = false,
  }) {
    return OnlineConsultBookingState(
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      pendingReports: pendingReports ?? this.pendingReports,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      booking: booking ?? this.booking,
    );
  }
}

class OnlineConsultBookingNotifier extends StateNotifier<OnlineConsultBookingState> {
  OnlineConsultBookingNotifier(this._paymentFlow)
      : super(const OnlineConsultBookingState());

  final BookingPaymentFlow _paymentFlow;

  void selectSlot(BookableSlot? slot) {
    if (slot == null) {
      state = state.copyWith(clearSlot: true, error: null);
    } else {
      state = state.copyWith(selectedSlot: slot, error: null);
    }
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
    return OnlineConsultBookingNotifier(ref.watch(bookingPaymentFlowProvider));
  },
);
