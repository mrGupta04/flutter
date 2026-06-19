/// Healthcare provider roles in the partner (admin) app.
enum ProviderType {
  doctor,
  nurse,
  ambulance,
  bloodBank;

  String get routeParam {
    switch (this) {
      case ProviderType.doctor:
        return 'doctor';
      case ProviderType.nurse:
        return 'nurse';
      case ProviderType.ambulance:
        return 'ambulance';
      case ProviderType.bloodBank:
        return 'blood-bank';
    }
  }

  String get label {
    switch (this) {
      case ProviderType.doctor:
        return 'Doctor';
      case ProviderType.nurse:
        return 'Nurse';
      case ProviderType.ambulance:
        return 'Ambulance';
      case ProviderType.bloodBank:
        return 'Blood Bank';
    }
  }

  String get registerRoute {
    switch (this) {
      case ProviderType.doctor:
        return '/registration-form';
      case ProviderType.nurse:
        return '/nurse-registration';
      case ProviderType.ambulance:
        return '/ambulance-registration';
      case ProviderType.bloodBank:
        return '/blood-bank-registration';
    }
  }

  String get profileRoute {
    switch (this) {
      case ProviderType.doctor:
        return '/doctor-dashboard';
      case ProviderType.nurse:
      case ProviderType.ambulance:
      case ProviderType.bloodBank:
        return '/provider-profile';
    }
  }

  static ProviderType? fromRouteParam(String? value) {
    switch (value) {
      case 'doctor':
        return ProviderType.doctor;
      case 'nurse':
        return ProviderType.nurse;
      case 'ambulance':
        return ProviderType.ambulance;
      case 'blood-bank':
        return ProviderType.bloodBank;
      default:
        return null;
    }
  }
}
