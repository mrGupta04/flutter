import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bookable_slot_model.dart';
import '../../../data/models/previous_report_model.dart';
import '../../../data/repositories/booking_reports_repository.dart';
import '../../../data/repositories/online_consult_repository.dart';
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

  HomeVisitBookingState copyWith({
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
    return HomeVisitBookingState(
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

class HomeVisitBookingNotifier extends StateNotifier<HomeVisitBookingState> {
  HomeVisitBookingNotifier(
    this._repository,
    this._reportsRepository,
    this._doctorId,
  ) : super(const HomeVisitBookingState());

  final OnlineConsultRepository _repository;
  final BookingReportsRepository _reportsRepository;
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

  void setPendingReports(List<PendingPreviousReport> reports) {
    state = state.copyWith(pendingReports: reports, error: null);
  }

  Future<void> _uploadPendingReports(String bookingId) async {
    for (final report in state.pendingReports) {
      await _reportsRepository.uploadPreviousReport(
        bookingId: bookingId,
        bytes: Uint8List.fromList(report.bytes),
        fileName: report.fileName,
      );
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
    double? patientLatitude,
    double? patientLongitude,
  }) async {
    final slot = state.selectedSlot;
    if (slot == null) {
      state = state.copyWith(error: 'Please select an appointment time');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final response = await _repository.requestHomeVisit(
        doctorId: doctorId,
        patientName: patientName,
        patientMobile: patientMobile,
        patientEmail: patientEmail,
        patientNotes: patientNotes,
        patientAddress: patientAddress,
        patientCity: patientCity,
        patientState: patientState,
        patientPincode: patientPincode,
        visitReason: visitReason,
        patientLatitude: patientLatitude,
        patientLongitude: patientLongitude,
        dayOfWeek: slot.dayOfWeek,
        startHour: slot.startHour,
        slotStart: slot.slotStart,
      );

      if (response.success && response.data != null) {
        if (state.pendingReports.isNotEmpty) {
          try {
            await _uploadPendingReports(response.data!.id);
          } catch (_) {
            // Booking succeeded; report upload can be retried from dashboard.
          }
        }
        state = HomeVisitBookingState(booking: response.data);
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

final homeVisitBookingProvider = StateNotifierProvider.autoDispose
    .family<HomeVisitBookingNotifier, HomeVisitBookingState, String>(
  (ref, doctorId) {
    final notifier = HomeVisitBookingNotifier(
      ref.watch(onlineConsultRepositoryProvider),
      BookingReportsRepository(),
      doctorId,
    );
    ref.onDispose(() {
      notifier.releaseHold();
    });
    return notifier;
  },
);
