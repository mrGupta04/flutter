import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/doctor_availability_model.dart';
import '../../../data/models/doctor_booking_model.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';
import '../../auth/provider/provider_auth_provider.dart';
import '../../provider/provider/provider_profile_provider.dart';

final nurseDashboardRepositoryProvider = Provider(
  (ref) => NurseRegistrationRepository(),
);

class NurseDashboardState {
  final NurseModel? nurse;
  final DoctorAvailabilityModel? homeAvailability;
  final List<DoctorBookingModel> bookings;
  final bool isLoading;
  final bool isLoadingBookings;
  final bool isSavingAvailability;
  final String? error;
  final String? bookingsError;

  const NurseDashboardState({
    this.nurse,
    this.homeAvailability,
    this.bookings = const [],
    this.isLoading = false,
    this.isLoadingBookings = false,
    this.isSavingAvailability = false,
    this.error,
    this.bookingsError,
  });

  List<DoctorBookingModel> get pendingHomeVisitRequests => bookings
      .where((b) => b.isHomeVisit && b.isAwaitingDoctorApproval)
      .toList(growable: false);

  List<DoctorBookingModel> get upcomingHomeBookings => bookings
      .where((b) => b.isHomeVisit && b.isUpcoming && b.status == 'confirmed')
      .toList(growable: false);

  bool get needsAvailabilityUpdate =>
      homeAvailability?.needsUpdate == true ||
      (homeAvailability?.selectedSlotKeys.isEmpty ?? true);

  NurseDashboardState copyWith({
    NurseModel? nurse,
    DoctorAvailabilityModel? homeAvailability,
    List<DoctorBookingModel>? bookings,
    bool? isLoading,
    bool? isLoadingBookings,
    bool? isSavingAvailability,
    String? error,
    String? bookingsError,
  }) {
    return NurseDashboardState(
      nurse: nurse ?? this.nurse,
      homeAvailability: homeAvailability ?? this.homeAvailability,
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      isSavingAvailability:
          isSavingAvailability ?? this.isSavingAvailability,
      error: error,
      bookingsError: bookingsError,
    );
  }
}

class NurseDashboardNotifier extends StateNotifier<NurseDashboardState> {
  NurseDashboardNotifier(this._ref, this._repository)
      : super(const NurseDashboardState());

  final Ref _ref;
  final NurseRegistrationRepository _repository;

  Future<String?> _resolveNurseId() async {
    final fromState = state.nurse?.id;
    if (fromState != null && fromState.isNotEmpty) return fromState;
    final fromAuth = _ref.read(providerAuthProvider).entityId;
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    final fromProfile = _ref.read(providerProfileProvider).nurse?.id;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return TokenStorage.instance.getNurseId();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    final nurseId = await _resolveNurseId();
    if (nurseId == null || nurseId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Nurse profile not found. Please sign in again.',
      );
      return;
    }

    final profileRes = await _repository.getProfile(nurseId: nurseId);
    final availRes = await _repository.getAvailability(nurseId: nurseId);

    if (profileRes.success && profileRes.data != null) {
      state = state.copyWith(
        nurse: profileRes.data,
        homeAvailability: availRes.data,
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: profileRes.error ?? 'Failed to load profile',
      );
    }
  }

  Future<void> loadBookings() async {
    state = state.copyWith(isLoadingBookings: true, bookingsError: null);
    final nurseId = await _resolveNurseId();
    if (nurseId == null) {
      state = state.copyWith(
        isLoadingBookings: false,
        bookingsError: 'Nurse ID not found',
      );
      return;
    }

    final response = await _repository.getBookings(nurseId: nurseId);
    if (response.success && response.data != null) {
      state = state.copyWith(
        bookings: response.data!,
        isLoadingBookings: false,
      );
    } else {
      state = state.copyWith(
        isLoadingBookings: false,
        bookingsError: response.error ?? 'Failed to load bookings',
      );
    }
  }

  Future<void> refreshAll() async {
    await loadProfile();
    await loadBookings();
  }

  Future<bool> saveAvailability(Set<String> selectedSlotKeys) async {
    final nurseId = await _resolveNurseId();
    if (nurseId == null) return false;

    state = state.copyWith(isSavingAvailability: true);
    final response = await _repository.saveAvailability(
      nurseId: nurseId,
      selectedSlotKeys: selectedSlotKeys,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(
        homeAvailability: response.data,
        isSavingAvailability: false,
      );
      return true;
    }
    state = state.copyWith(isSavingAvailability: false);
    return false;
  }

  Future<bool> approveHomeVisitRequest(String bookingId) async {
    final nurseId = await _resolveNurseId();
    final response = await _repository.approveHomeVisitRequest(
      bookingId: bookingId,
      nurseId: nurseId,
    );
    if (response.success) {
      await loadBookings();
      return true;
    }
    return false;
  }

  Future<bool> rejectHomeVisitRequest(String bookingId) async {
    final nurseId = await _resolveNurseId();
    final response = await _repository.rejectHomeVisitRequest(
      bookingId: bookingId,
      nurseId: nurseId,
    );
    if (response.success) {
      await loadBookings();
      return true;
    }
    return false;
  }
}

final nurseDashboardProvider =
    StateNotifierProvider<NurseDashboardNotifier, NurseDashboardState>((ref) {
  final repository = ref.watch(nurseDashboardRepositoryProvider);
  return NurseDashboardNotifier(ref, repository);
});
