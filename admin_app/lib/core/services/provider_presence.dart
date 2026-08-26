import '../models/provider_type.dart';
import 'doctor_presence_service.dart';
import 'nurse_presence_service.dart';
import 'token_storage.dart';

/// Starts or stops live heartbeats for the logged-in doctor/nurse.
Future<void> syncProviderPresence({required bool online}) async {
  final typeKey = await TokenStorage.instance.getProviderType();
  final type = ProviderType.fromRouteParam(typeKey ?? '') ??
      (typeKey == 'bloodbank' ? ProviderType.bloodBank : null);

  if (type == ProviderType.doctor) {
    if (online) {
      await DoctorPresenceService.instance.goOnline();
    } else {
      await DoctorPresenceService.instance.goOffline(immediate: true);
    }
    return;
  }

  if (type == ProviderType.nurse) {
    if (online) {
      await NursePresenceService.instance.goOnline();
    } else {
      await NursePresenceService.instance.goOffline(immediate: true);
    }
  }
}
