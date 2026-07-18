import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/provider_type.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/models/doctor_availability_model.dart';
import '../../../data/models/doctor_model.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/ambulance_registration_repository.dart';
import '../../../data/repositories/blood_bank_registration_repository.dart';
import '../../../data/repositories/doctor_registration_repository.dart';
import '../../../data/repositories/nurse_registration_repository.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/services/dio_service.dart';
import '../../../core/constants/app_constants.dart';

class ProviderBookingItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;

  const ProviderBookingItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });
}

class ProviderProfileState {
  const ProviderProfileState({
    this.providerType,
    this.doctor,
    this.nurse,
    this.ambulance,
    this.bloodBank,
    this.bookings = const [],
    this.availabilityReminder,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  final ProviderType? providerType;
  final DoctorModel? doctor;
  final NurseModel? nurse;
  final AmbulanceModel? ambulance;
  final BloodBankModel? bloodBank;
  final AvailabilityReminder? availabilityReminder;
  final List<ProviderBookingItem> bookings;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  String get displayName {
    if (doctor != null) return doctor!.fullName;
    if (nurse != null) return nurse!.displayName;
    if (ambulance != null) {
      return ambulance!.serviceName ?? ambulance!.ownerName ?? 'Ambulance';
    }
    if (bloodBank != null) {
      return bloodBank!.institutionName ?? 'Blood Bank';
    }
    return 'Partner';
  }

  VerificationStatus? get verificationStatus {
    return doctor?.verificationStatus ??
        nurse?.verificationStatus ??
        ambulance?.verificationStatus ??
        bloodBank?.verificationStatus;
  }

  bool get needsAvailabilityUpdate => availabilityReminder?.needsUpdate == true;

  ProviderProfileState copyWith({
    ProviderType? providerType,
    DoctorModel? doctor,
    NurseModel? nurse,
    AmbulanceModel? ambulance,
    BloodBankModel? bloodBank,
    List<ProviderBookingItem>? bookings,
    AvailabilityReminder? availabilityReminder,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) {
    return ProviderProfileState(
      providerType: providerType ?? this.providerType,
      doctor: doctor ?? this.doctor,
      nurse: nurse ?? this.nurse,
      ambulance: ambulance ?? this.ambulance,
      bloodBank: bloodBank ?? this.bloodBank,
      availabilityReminder: availabilityReminder ?? this.availabilityReminder,
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
    );
  }
}

class ProviderProfileNotifier extends StateNotifier<ProviderProfileState> {
  ProviderProfileNotifier()
      : _doctorRepo = DoctorRegistrationRepository(),
        _nurseRepo = NurseRegistrationRepository(),
        _ambulanceRepo = AmbulanceRegistrationRepository(),
        _bloodBankRepo = BloodBankRegistrationRepository(),
        _dio = DioService(),
        super(const ProviderProfileState());

  final DoctorRegistrationRepository _doctorRepo;
  final NurseRegistrationRepository _nurseRepo;
  final AmbulanceRegistrationRepository _ambulanceRepo;
  final BloodBankRegistrationRepository _bloodBankRepo;
  final DioService _dio;

  Future<ProviderType?> _resolveType() async {
    final key = await TokenStorage.instance.getProviderType();
    return ProviderType.fromRouteParam(key) ??
        (key == 'bloodbank' ? ProviderType.bloodBank : null);
  }

  Future<void> loadAll({bool silent = false}) async {
    final hasCachedProfile = state.doctor != null ||
        state.nurse != null ||
        state.ambulance != null ||
        state.bloodBank != null;

    if (!silent || !hasCachedProfile) {
      state = state.copyWith(
        isLoading: !hasCachedProfile,
        error: null,
      );
    } else {
      state = state.copyWith(error: null);
    }

    final type = await _resolveType();
    if (type == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'No partner profile session',
      );
      return;
    }

    try {
      if (type == ProviderType.doctor) {
        final res = await _doctorRepo.getDoctorProfile();
        if (res.success && res.data != null) {
          final doctor = res.data!;
          if (doctor.id != null && doctor.id!.isNotEmpty) {
            await TokenStorage.instance.saveDoctorId(doctor.id!);
          }
          state = ProviderProfileState(
            providerType: type,
            doctor: doctor,
            bookings: state.bookings,
            availabilityReminder: state.availabilityReminder,
            isLoading: false,
          );
          await Future.wait([
            _loadDoctorExtras(doctor),
            loadBookings(),
          ]);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: res.error ?? 'Failed to load profile',
          );
        }
      } else if (type == ProviderType.nurse) {
        final res = await _nurseRepo.getProfile();
        if (res.success && res.data != null) {
          state = ProviderProfileState(
            providerType: type,
            nurse: res.data,
            bookings: state.bookings,
            isLoading: false,
          );
          await loadBookings();
        } else {
          state = state.copyWith(
            isLoading: false,
            error: res.error ?? 'Failed to load profile',
          );
        }
      } else if (type == ProviderType.ambulance) {
        final res = await _ambulanceRepo.getProfile();
        if (res.success && res.data != null) {
          state = ProviderProfileState(
            providerType: type,
            ambulance: res.data,
            bookings: state.bookings,
            isLoading: false,
          );
          await loadBookings();
        } else {
          state = state.copyWith(
            isLoading: false,
            error: res.error ?? 'Failed to load profile',
          );
        }
      } else if (type == ProviderType.bloodBank) {
        final res = await _bloodBankRepo.getProfile();
        if (res.success && res.data != null) {
          state = ProviderProfileState(
            providerType: type,
            bloodBank: res.data,
            bookings: state.bookings,
            isLoading: false,
          );
          await loadBookings();
        } else {
          state = state.copyWith(
            isLoading: false,
            error: res.error ?? 'Failed to load profile',
          );
        }
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: AppConstants.errorSomethingWentWrong,
      );
    }
  }

  Future<void> _loadDoctorExtras(DoctorModel doctor) async {
    final doctorId = doctor.id;
    if (doctorId == null || doctorId.isEmpty) return;

    try {
      final availRes = await _doctorRepo.getAvailability(doctorId: doctorId);
      AvailabilityReminder? reminder;
      if (availRes.data?.needsUpdate == true) {
        reminder = AvailabilityReminder(
          needsUpdate: true,
          message: availRes.data?.reminderMessage ?? availRes.message,
        );
      } else {
        reminder = const AvailabilityReminder(needsUpdate: false);
      }
      state = state.copyWith(availabilityReminder: reminder);
    } catch (_) {
      state = state.copyWith(
        availabilityReminder: const AvailabilityReminder(needsUpdate: false),
      );
    }
  }

  Future<void> loadBookings() async {
    final type = state.providerType ?? await _resolveType();
    if (type == null) return;

    late final String endpoint;
    final params = <String, String>{};
    if (type == ProviderType.nurse) {
      endpoint = AppConstants.endpointNurseBookings;
      final id = state.nurse?.id ?? await TokenStorage.instance.getNurseId();
      if (id != null) params['nurseId'] = id;
    } else if (type == ProviderType.ambulance) {
      endpoint = AppConstants.endpointAmbulanceBookings;
      final id =
          state.ambulance?.id ?? await TokenStorage.instance.getAmbulanceId();
      if (id != null) params['ambulanceId'] = id;
    } else if (type == ProviderType.bloodBank) {
      endpoint = AppConstants.endpointBloodBankBookings;
      final id =
          state.bloodBank?.id ?? await TokenStorage.instance.getBloodBankId();
      if (id != null) params['bloodBankId'] = id;
    } else {
      endpoint = AppConstants.endpointDoctorBookings;
      final id = await TokenStorage.instance.getDoctorId();
      if (id != null) params['doctorId'] = id;
    }

    try {
      final response = await _dio.get(endpoint, queryParameters: params);
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      final bookings = list.map((e) {
        final m = e as Map<String, dynamic>;
        if (type == ProviderType.ambulance) {
          return ProviderBookingItem(
            id: m['id']?.toString() ?? '',
            title: m['patientName']?.toString() ?? 'Emergency request',
            subtitle: m['pickupAddress']?.toString() ??
                m['ambulanceServiceName']?.toString() ??
                '',
            status: m['status']?.toString() ?? 'requested',
          );
        }
        return ProviderBookingItem(
          id: m['id']?.toString() ?? '',
          title: m['title']?.toString() ??
              m['patientName']?.toString() ??
              'Booking',
          subtitle: m['subtitle']?.toString() ??
              m['label']?.toString() ??
              m['timeSlot']?.toString() ??
              '',
          status: m['status']?.toString() ?? 'pending',
        );
      }).toList();
      state = state.copyWith(bookings: bookings);
    } catch (_) {
      state = state.copyWith(bookings: const []);
    }
  }

  Future<bool> updateAmbulanceBookingStatus({
    required String bookingId,
    required String status,
    String? rejectionReason,
    int? estimatedArrivalMinutes,
  }) async {
    final ambulanceId =
        state.ambulance?.id ?? await TokenStorage.instance.getAmbulanceId();
    if (ambulanceId == null) return false;
    try {
      await _dio.post(
        '${AppConstants.endpointAmbulanceBookings}/$bookingId/status',
        data: {
          'ambulanceId': ambulanceId,
          'status': status,
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
          if (estimatedArrivalMinutes != null)
            'estimatedArrivalMinutes': estimatedArrivalMinutes,
        },
      );
      await loadBookings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> shareAmbulanceLiveLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
  }) async {
    final ambulanceId =
        state.ambulance?.id ?? await TokenStorage.instance.getAmbulanceId();
    if (ambulanceId == null) return false;
    try {
      await _dio.post(
        AppConstants.endpointAmbulanceBookingLocation(bookingId),
        data: {
          'ambulanceId': ambulanceId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateNurse(NurseModel nurse) async {
    state = state.copyWith(isUpdating: true, error: null);
    final res = await _nurseRepo.updateProfile(nurse);
    if (res.success && res.data != null) {
      state = state.copyWith(nurse: res.data, isUpdating: false);
      return true;
    }
    state = state.copyWith(
      isUpdating: false,
      error: res.error ?? 'Update failed',
    );
    return false;
  }

  Future<bool> updateAmbulance(AmbulanceModel ambulance) async {
    state = state.copyWith(isUpdating: true, error: null);
    final res = await _ambulanceRepo.updateProfile(ambulance);
    if (res.success && res.data != null) {
      state = state.copyWith(ambulance: res.data, isUpdating: false);
      return true;
    }
    state = state.copyWith(
      isUpdating: false,
      error: res.error ?? 'Update failed',
    );
    return false;
  }

  Future<bool> updateBloodBank(BloodBankModel bloodBank) async {
    state = state.copyWith(isUpdating: true, error: null);
    final res = await _bloodBankRepo.updateProfile(bloodBank);
    if (res.success && res.data != null) {
      state = state.copyWith(bloodBank: res.data, isUpdating: false);
      return true;
    }
    state = state.copyWith(
      isUpdating: false,
      error: res.error ?? 'Update failed',
    );
    return false;
  }
}

final providerProfileProvider =
    StateNotifierProvider<ProviderProfileNotifier, ProviderProfileState>((ref) {
  return ProviderProfileNotifier();
});
