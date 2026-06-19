import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookable_slot_model.dart';

import '../../../data/services/booking_payment_flow.dart';

import '../../online_consult/provider/online_consult_provider.dart';



final bookableSlotsForVisitProvider =

    FutureProvider.family<BookableSlotsResponse, String>((ref, doctorId) async {

  final repo = ref.watch(onlineConsultRepositoryProvider);

  final res = await repo.getBookableSlots(

    doctorId: doctorId,

    consultationType: 'visit_site',

  );

  if (!res.success || res.data == null) {

    throw Exception(res.error ?? 'Could not load appointment slots');

  }

  return res.data!;

});



class HospitalVisitBookingState {

  const HospitalVisitBookingState({

    this.selectedSlot,

    this.isSubmitting = false,

    this.error,

    this.booking,

  });



  final BookableSlot? selectedSlot;

  final bool isSubmitting;

  final String? error;

  final ConsultationBookingResult? booking;



  HospitalVisitBookingState copyWith({

    BookableSlot? selectedSlot,

    bool? isSubmitting,

    String? error,

    ConsultationBookingResult? booking,

    bool clearSlot = false,

  }) {

    return HospitalVisitBookingState(

      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),

      isSubmitting: isSubmitting ?? this.isSubmitting,

      error: error,

      booking: booking ?? this.booking,

    );

  }

}



class HospitalVisitBookingNotifier

    extends StateNotifier<HospitalVisitBookingState> {

  HospitalVisitBookingNotifier(this._paymentFlow)

      : super(const HospitalVisitBookingState());



  final BookingPaymentFlow _paymentFlow;



  void selectSlot(BookableSlot? slot) {

    if (slot == null) {

      state = state.copyWith(clearSlot: true, error: null);

    } else {

      state = state.copyWith(selectedSlot: slot, error: null);

    }

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

        consultationType: 'visit_site',

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

        state = HospitalVisitBookingState(booking: booking);

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



final hospitalVisitBookingProvider = StateNotifierProvider.autoDispose

    .family<HospitalVisitBookingNotifier, HospitalVisitBookingState, String>(

  (ref, doctorId) {

    return HospitalVisitBookingNotifier(ref.watch(bookingPaymentFlowProvider));

  },

);

