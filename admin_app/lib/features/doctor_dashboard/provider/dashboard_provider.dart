import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../auth/provider/provider_auth_provider.dart';
import '../../doctor_registration/provider/registration_provider.dart';
import '../../provider/provider/provider_profile_provider.dart';

/// Provider for doctor dashboard
final doctorDashboardRepositoryProvider = Provider((ref) {
  return DoctorRegistrationRepository();
});

/// State for doctor dashboard
class DoctorDashboardState {
  final DoctorModel? doctor;
  final List<DoctorDocumentModel> documents;
  final DoctorAvailabilityModel? availability;
  final DoctorAvailabilityModel? clinicAvailability;
  final DoctorAvailabilityModel? homeAvailability;
  final AvailabilityReminder? availabilityReminder;
  final List<DoctorBookingModel> bookings;
  final DoctorBookingStats bookingStats;
  final bool isLoadingBookings;
  final String? bookingsError;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final bool isSavingAvailability;

  DoctorDashboardState({
    this.doctor,
    this.documents = const [],
    this.availability,
    this.clinicAvailability,
    this.homeAvailability,
    this.availabilityReminder,
    this.bookings = const [],
    this.bookingStats = const DoctorBookingStats(),
    this.isLoadingBookings = false,
    this.bookingsError,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
    this.isSavingAvailability = false,
  });

  List<DoctorBookingModel> get upcomingBookings =>
      bookings.where((b) => b.isUpcoming).toList();

  List<DoctorBookingModel> get upcomingOnlineBookings => bookings
      .where((b) => b.isUpcoming && b.isOnlineConsult)
      .toList(growable: false);

  List<DoctorBookingModel> get upcomingClinicBookings => bookings
      .where((b) => b.isUpcoming && b.isClinicVisit)
      .toList(growable: false);

  List<DoctorBookingModel> get upcomingHomeBookings => bookings
      .where((b) => b.isUpcoming && b.isHomeVisit)
      .toList(growable: false);

  List<DoctorBookingModel> get pastBookings =>
      bookings.where((b) => !b.isUpcoming).toList();

  bool get needsAvailabilityUpdate =>
      availabilityReminder?.needsUpdate == true ||
      availability?.needsUpdate == true;

  DoctorDashboardState copyWith({
    DoctorModel? doctor,
    List<DoctorDocumentModel>? documents,
    DoctorAvailabilityModel? availability,
    DoctorAvailabilityModel? clinicAvailability,
    DoctorAvailabilityModel? homeAvailability,
    AvailabilityReminder? availabilityReminder,
    List<DoctorBookingModel>? bookings,
    DoctorBookingStats? bookingStats,
    bool? isLoadingBookings,
    String? bookingsError,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    bool? isSavingAvailability,
  }) {
    return DoctorDashboardState(
      doctor: doctor ?? this.doctor,
      documents: documents ?? this.documents,
      availability: availability ?? this.availability,
      clinicAvailability: clinicAvailability ?? this.clinicAvailability,
      homeAvailability: homeAvailability ?? this.homeAvailability,
      availabilityReminder:
          availabilityReminder ?? this.availabilityReminder,
      bookings: bookings ?? this.bookings,
      bookingStats: bookingStats ?? this.bookingStats,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      bookingsError: bookingsError,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
      isSavingAvailability:
          isSavingAvailability ?? this.isSavingAvailability,
    );
  }
}

/// Notifier for doctor dashboard
class DoctorDashboardNotifier extends StateNotifier<DoctorDashboardState> {
  DoctorDashboardNotifier(this._ref, this.repository) : super(DoctorDashboardState());

  final Ref _ref;
  final DoctorRegistrationRepository repository;

  /// Initialize dashboard with doctor data
  void initializeDashboard(DoctorModel doctor) {
    state = state.copyWith(doctor: doctor);
  }

  Future<String?> _resolveDoctorId() async {
    final fromState = state.doctor?.id;
    if (fromState != null && fromState.isNotEmpty) return fromState;

    final fromRegistration = _ref.read(doctorRegistrationProvider).doctor?.id;
    if (fromRegistration != null && fromRegistration.isNotEmpty) {
      return fromRegistration;
    }

    final fromAuth = _ref.read(providerAuthProvider).entityId;
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;

    return TokenStorage.instance.getDoctorId();
  }

  Future<void> loadProfile() async {
    final cachedDoctor = state.doctor ??
        _ref.read(doctorRegistrationProvider).doctor ??
        _ref.read(providerProfileProvider).doctor;
    if (cachedDoctor != null) {
      state = state.copyWith(doctor: cachedDoctor, isLoading: false);
    }

    final doctorId = cachedDoctor?.id ?? await _resolveDoctorId();

    if (doctorId == null || doctorId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Doctor ID not found. Please sign in again.',
      );
      return;
    }

    state = state.copyWith(isLoading: cachedDoctor == null, error: null);

    try {
      final response = await repository.getDoctorProfile(doctorId: doctorId);
      if (response.success && response.data != null) {
        final fresh = response.data!;
        _ref.read(doctorRegistrationProvider.notifier).updateDoctorData(fresh);
        state = state.copyWith(
          doctor: fresh,
          isLoading: false,
          error: null,
        );
        await Future.wait([
          loadAvailability(),
          loadBookings(),
          loadDocuments(),
        ]);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load profile',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: cachedDoctor != null ? null : 'An error occurred',
      );
    }
  }

  /// Update doctor profile
  Future<bool> updateProfile(DoctorModel updatedDoctor) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final response = await repository.updateDoctorProfile(
        doctor: updatedDoctor,
      );

      if (response.success && response.data != null) {
        final fresh = response.data!;
        _ref.read(doctorRegistrationProvider.notifier).updateDoctorData(fresh);
        state = state.copyWith(
          doctor: fresh,
          isUpdating: false,
          error: null,
        );
        await loadBookings();
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: response.error ?? 'Failed to update profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'An error occurred',
      );
      return false;
    }
  }

  Future<void> loadDocuments() async {
    final doctorId = await _resolveDoctorId();
    if (doctorId == null) return;

    try {
      final response = await repository.getDocuments(doctorId: doctorId);
      if (response.success && response.data != null) {
        state = state.copyWith(documents: response.data!);
      }
    } catch (_) {
      // Non-fatal
    }
  }

  /// Upload or re-upload a document (resets rejected docs to pending on the server).
  Future<bool> uploadDocument({
    required String filePath,
    required DocumentType documentType,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final doctorId = await _resolveDoctorId();
      if (doctorId == null || doctorId.isEmpty) {
        state = state.copyWith(
          isUpdating: false,
          error: 'Doctor ID not found',
        );
        return false;
      }

      final response = await repository.uploadDocument(
        doctorId: doctorId,
        filePath: filePath,
        documentType: documentType,
      );

      if (response.success && response.data != null) {
        final uploaded = response.data!;
        final updatedDocuments = [...state.documents];
        final existingIndex = updatedDocuments.indexWhere(
          (doc) => doc.documentType == documentType,
        );
        if (existingIndex >= 0) {
          updatedDocuments[existingIndex] = uploaded;
        } else {
          updatedDocuments.add(uploaded);
        }
        state = state.copyWith(
          documents: updatedDocuments,
          isUpdating: false,
          error: null,
        );
        await loadDocuments();
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: response.error ?? 'Failed to upload document',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'An error occurred',
      );
      return false;
    }
  }

  Future<void> loadAvailability() async {
    final doctorId = await _resolveDoctorId();
    if (doctorId == null) return;

    try {
      final doctor = state.doctor;
      DoctorAvailabilityModel? onlineAvail;
      DoctorAvailabilityModel? clinicAvail;
      DoctorAvailabilityModel? homeAvail;

      if (doctor?.offersOnlineConsult != false) {
        final response = await repository.getAvailability(
          doctorId: doctorId,
          consultationType: 'online_consult',
        );
        if (response.success && response.data != null) {
          onlineAvail = response.data;
        }
      }

      if (doctor?.offersVisitSite == true) {
        final response = await repository.getAvailability(
          doctorId: doctorId,
          consultationType: 'visit_site',
        );
        if (response.success && response.data != null) {
          clinicAvail = response.data;
        }
      }

      if (doctor?.offersBookHome == true) {
        final response = await repository.getAvailability(
          doctorId: doctorId,
          consultationType: 'book_home',
        );
        if (response.success && response.data != null) {
          homeAvail = response.data;
        }
      }

      final needsUpdate =
          (onlineAvail?.needsUpdate ?? false) ||
          (clinicAvail?.needsUpdate ?? false) ||
          (homeAvail?.needsUpdate ?? false);
      final reminderMessage = [
        if (onlineAvail?.needsUpdate == true) onlineAvail?.reminderMessage,
        if (clinicAvail?.needsUpdate == true) clinicAvail?.reminderMessage,
        if (homeAvail?.needsUpdate == true) homeAvail?.reminderMessage,
      ].whereType<String>().join(' ');

      state = state.copyWith(
        availability: onlineAvail,
        clinicAvailability: clinicAvail,
        homeAvailability: homeAvail,
        availabilityReminder: needsUpdate
            ? AvailabilityReminder(
                needsUpdate: true,
                message: reminderMessage.isNotEmpty
                    ? reminderMessage
                    : 'Please update your availability for the next week.',
                suggestedWeekStart: onlineAvail?.weekStartDate ??
                    clinicAvail?.weekStartDate ??
                    homeAvail?.weekStartDate,
                suggestedWeekEnd: onlineAvail?.weekEndDate ??
                    clinicAvail?.weekEndDate ??
                    homeAvail?.weekEndDate,
              )
            : const AvailabilityReminder(needsUpdate: false),
      );
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> refreshAll() async {
    await loadProfile();
  }

  Future<void> loadBookings() async {
    final doctorId = await _resolveDoctorId();
    if (doctorId == null) return;

    state = state.copyWith(isLoadingBookings: true, bookingsError: null);
    try {
      final response = await repository.getBookings(doctorId: doctorId);
      if (response.success && response.data != null) {
        final bookings = response.data!;
        state = state.copyWith(
          bookings: bookings,
          bookingStats: DoctorBookingStats.fromBookings(bookings),
          isLoadingBookings: false,
          bookingsError: null,
        );
      } else {
        state = state.copyWith(
          isLoadingBookings: false,
          bookingsError: response.error ?? 'Failed to load bookings',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoadingBookings: false,
        bookingsError: 'Failed to load bookings',
      );
    }
  }

  Future<bool> saveAvailability(
    Set<String> selectedSlotKeys, {
    String consultationType = 'online_consult',
  }) async {
    final doctorId = await _resolveDoctorId();
    if (doctorId == null || doctorId.isEmpty) return false;

    state = state.copyWith(isSavingAvailability: true, error: null);
    try {
      // Let the server resolve the active bookable week — avoids saving to a
      // future week while the current week is still open for patients.
      final response = await repository.saveAvailability(
        doctorId: doctorId,
        selectedSlotKeys: selectedSlotKeys,
        weekStartDate: state.availabilityReminder?.needsUpdate == true
            ? state.availabilityReminder?.suggestedWeekStart
            : null,
        consultationType: consultationType,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(isSavingAvailability: false);
        await loadAvailability();
        await loadBookings();
        return true;
      }
      state = state.copyWith(
        isSavingAvailability: false,
        error: response.error ?? 'Failed to save availability',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSavingAvailability: false,
        error: 'An error occurred',
      );
      return false;
    }
  }

  Future<bool> verifyClinicAppointment(String appointmentCode) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final response =
          await repository.verifyClinicAppointment(appointmentCode: appointmentCode);
      if (response.success) {
        await loadBookings();
        state = state.copyWith(isUpdating: false, error: null);
        return true;
      }
      state = state.copyWith(
        isUpdating: false,
        error: response.error ?? 'Verification failed',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Verification failed',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for doctor dashboard notifier
final doctorDashboardProvider =
    StateNotifierProvider<DoctorDashboardNotifier, DoctorDashboardState>((ref) {
  final repository = ref.watch(doctorDashboardRepositoryProvider);
  return DoctorDashboardNotifier(ref, repository);
});

/// Provider for profile completion percentage
final profileCompletionProvider = Provider<int>((ref) {
  final dashboard = ref.watch(doctorDashboardProvider);
  final doctor = dashboard.doctor;

  if (doctor == null) return 0;

  int completedFields = 0;
  int totalFields = 17;

  if (doctor.firstName != null && doctor.firstName!.isNotEmpty) completedFields++;
  if (doctor.lastName != null && doctor.lastName!.isNotEmpty) completedFields++;
  if (doctor.email != null && doctor.email!.isNotEmpty) completedFields++;
  if (doctor.mobileNumber != null && doctor.mobileNumber!.isNotEmpty) completedFields++;
  if (doctor.profilePicture != null && doctor.profilePicture!.isNotEmpty) completedFields++;
  if (doctor.medicalRegistrationNumber != null &&
      doctor.medicalRegistrationNumber!.isNotEmpty) {
    completedFields++;
  }
  if (doctor.specializations != null && doctor.specializations!.isNotEmpty) completedFields++;
  if (doctor.qualification != null && doctor.qualification!.isNotEmpty) completedFields++;
  if (doctor.yearsOfExperience != null) completedFields++;
  if (doctor.languagesSpoken != null && doctor.languagesSpoken!.isNotEmpty) {
    completedFields++;
  }
  if (doctor.bio != null && doctor.bio!.trim().isNotEmpty) completedFields++;
  if (doctor.clinicName != null && doctor.clinicName!.isNotEmpty) completedFields++;
  if (doctor.consultationFee != null) completedFields++;
  if (doctor.address != null && doctor.address!.isNotEmpty) completedFields++;
  if (doctor.city != null && doctor.city!.isNotEmpty) completedFields++;
  if (doctor.state != null && doctor.state!.isNotEmpty) completedFields++;
  if (doctor.pincode != null && doctor.pincode!.isNotEmpty) completedFields++;

  return ((completedFields / totalFields) * 100).toInt();
});
