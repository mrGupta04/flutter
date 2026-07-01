/// Healthcare provider roles in the partner (admin) app.
enum ProviderType {
  doctor,
  nurse,
  ambulance,
  bloodBank,
  lab,
  scanCenter;

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
      case ProviderType.lab:
        return 'lab';
      case ProviderType.scanCenter:
        return 'scan-center';
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
      case ProviderType.lab:
        return 'Diagnostic Lab';
      case ProviderType.scanCenter:
        return 'Scan Center';
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
      case ProviderType.lab:
        return '/lab-registration';
      case ProviderType.scanCenter:
        return '/scan-registration';
    }
  }

  String get profileRoute {
    switch (this) {
      case ProviderType.doctor:
        return '/doctor-dashboard';
      case ProviderType.nurse:
        return '/nurse-dashboard';
      case ProviderType.scanCenter:
        return '/scan-dashboard';
      case ProviderType.bloodBank:
        return '/blood-bank-dashboard';
      case ProviderType.ambulance:
      case ProviderType.lab:
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
      case 'lab':
        return ProviderType.lab;
      case 'scan-center':
      case 'scan_center':
        return ProviderType.scanCenter;
      default:
        return null;
    }
  }
}
