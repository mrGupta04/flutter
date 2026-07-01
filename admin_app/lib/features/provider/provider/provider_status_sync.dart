import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

import '../../../core/models/provider_type.dart';

import '../../../core/services/token_storage.dart';

import '../../auth/provider/provider_auth_provider.dart';

import '../../../data/models/doctor_model.dart';

import '../../ambulance_registration/provider/ambulance_registration_provider.dart';

import '../../blood_bank_registration/provider/blood_bank_registration_provider.dart';

import '../../doctor_registration/provider/registration_provider.dart';

import '../../nurse_registration/provider/nurse_registration_provider.dart';

import '../../lab_registration/provider/lab_registration_provider.dart';
import '../../scan_registration/provider/scan_registration_provider.dart';
import 'provider_profile_provider.dart';

/// Resolves signed-in partner type from storage (not only in-memory auth).
Future<ProviderType?> resolveStoredProviderType() async {
  final key = await TokenStorage.instance.getProviderType();
  return ProviderType.fromRouteParam(key) ??
      (key == 'bloodbank' ? ProviderType.bloodBank : null);
}

/// True when a provider JWT is stored (dashboard routes only need this).
Future<bool> hasProviderSession() async {
  final token = await TokenStorage.instance.getToken();
  return token != null && token.isNotEmpty;
}

/// Loads latest doctor/nurse profile from API and syncs local caches.
Future<void> refreshProviderApplicationStatus(
  WidgetRef ref, {
  bool silent = false,
}) async {
  final type = await resolveStoredProviderType();

  if (type == ProviderType.doctor) {
    final doctorId = await TokenStorage.instance.getDoctorId() ??
        ref.read(doctorRegistrationProvider).doctor?.id;
    if (doctorId != null && doctorId.isNotEmpty) {
      await ref
          .read(doctorRegistrationProvider.notifier)
          .refreshDoctorFromApi(doctorId: doctorId);
    }
  } else if (type == ProviderType.lab) {
    final labId = await TokenStorage.instance.getLabId() ??
        ref.read(labRegistrationProvider).lab?.id;
    if (labId != null && labId.isNotEmpty) {
      await ref
          .read(labRegistrationProvider.notifier)
          .refreshLabFromApi(labId: labId);
    }
  } else if (type == ProviderType.scanCenter) {
    final scanCenterId = await TokenStorage.instance.getScanCenterId() ??
        ref.read(scanRegistrationProvider).center?.id;
    if (scanCenterId != null && scanCenterId.isNotEmpty) {
      await ref.read(scanRegistrationProvider.notifier).refreshScanCenterFromApi(
            scanCenterId: scanCenterId,
          );
    }
  } else if (type == ProviderType.bloodBank) {
    final bloodBankId = await TokenStorage.instance.getBloodBankId() ??
        ref.read(bloodBankRegistrationProvider).bloodBank?.id;
    if (bloodBankId != null && bloodBankId.isNotEmpty) {
      await ref
          .read(bloodBankRegistrationProvider.notifier)
          .refreshFromApi(bloodBankId: bloodBankId);
    }
  }

  await ref.read(providerProfileProvider.notifier).loadAll(silent: silent);
  final profile = ref.read(providerProfileProvider);

  if (profile.doctor != null) {
    ref
        .read(doctorRegistrationProvider.notifier)
        .updateDoctorData(profile.doctor!);
    final id = profile.doctor!.id;
    if (id != null && id.isNotEmpty) {
      await TokenStorage.instance.saveDoctorId(id);
    }
  }
  if (profile.nurse != null) {
    ref.read(nurseRegistrationProvider.notifier).setNurse(profile.nurse!);
  }
  if (profile.ambulance != null) {
    ref
        .read(ambulanceRegistrationProvider.notifier)
        .setAmbulance(profile.ambulance!);
  }
  if (profile.bloodBank != null) {
    ref
        .read(bloodBankRegistrationProvider.notifier)
        .setBloodBank(profile.bloodBank!);
  }
  final lab = ref.read(labRegistrationProvider).lab;
  if (lab != null) {
    ref.read(labRegistrationProvider.notifier).setLab(lab);
  }
  final scanCenter = ref.read(scanRegistrationProvider).center;
  if (scanCenter != null) {
    ref.read(scanRegistrationProvider.notifier).setScanCenter(scanCenter);
  }
}

/// Opens the correct dashboard for the signed-in provider (doctor practice or partner profile).
Future<void> openProviderDashboard(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(providerAuthProvider);

  if (!auth.isAuthenticated) {
    final hasSession = await hasProviderSession();
    if (!hasSession) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please sign in or complete registration to open your dashboard',
            ),
          ),
        );
      }
      return;
    }
  }

  var type = auth.providerType ?? await resolveStoredProviderType();
  if (type == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not determine your partner type. Please sign in again.',
          ),
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;

  if (type == ProviderType.doctor) {
    context.push(AppConstants.routeDoctorDashboard);
  } else if (type == ProviderType.scanCenter) {
    context.push(AppConstants.routeScanDashboard);
  } else if (type == ProviderType.bloodBank) {
    context.push(AppConstants.routeBloodBankDashboard);
  } else {
    context.push(AppConstants.routeProviderProfile);
  }

  Future.microtask(() async {
    await ref.read(providerAuthProvider.notifier).refreshProfile();
    await refreshProviderApplicationStatus(ref, silent: true);
  });
}

/// Reads verification status from API-backed profile or registration cache.
VerificationStatus? readProviderVerificationStatus(WidgetRef ref) {
  final profile = ref.watch(providerProfileProvider);
  final profileDoctor = profile.doctor;
  if (profileDoctor != null) {
    return _effectiveVerificationStatus(profileDoctor);
  }
  final fromProfile = profile.verificationStatus;
  if (fromProfile != null) return fromProfile;

  final doctor = ref.watch(doctorRegistrationProvider).doctor;
  if (doctor != null) {
    return _effectiveVerificationStatus(doctor);
  }
  final nurse = ref.watch(nurseRegistrationProvider).nurse;
  if (nurse?.verificationStatus != null) return nurse!.verificationStatus;

  final lab = ref.watch(labRegistrationProvider).lab;
  if (lab?.verificationStatus != null) return lab!.verificationStatus;

  final scanCenter = ref.watch(scanRegistrationProvider).center;
  if (scanCenter?.verificationStatus != null) {
    return scanCenter!.verificationStatus;
  }

  return null;
}

VerificationStatus? _effectiveVerificationStatus(DoctorModel doctor) {
  if (doctor.isApproved == true ||
      doctor.verificationStatus == VerificationStatus.verified) {
    return VerificationStatus.verified;
  }
  return doctor.verificationStatus;
}
