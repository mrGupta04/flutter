import '../../data/models/patient_user_model.dart';

/// Result returned when the user picks a location for a healthcare service.
class SelectedLocationResult {
  const SelectedLocationResult({
    required this.addressLine,
    this.city,
    this.state,
    this.pincode,
    this.landmark,
    this.label,
    this.contactName,
    this.phone,
    this.latitude,
    this.longitude,
    this.savedAddressId,
  });

  final String addressLine;
  final String? city;
  final String? state;
  final String? pincode;
  final String? landmark;
  final String? label;
  final String? contactName;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? savedAddressId;

  String get displayLine {
    final parts = [
      addressLine,
      if (landmark != null && landmark!.trim().isNotEmpty) landmark!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (state != null && state!.trim().isNotEmpty) state!.trim(),
      if (pincode != null && pincode!.trim().isNotEmpty) pincode!.trim(),
    ];
    return parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  factory SelectedLocationResult.fromSaved(SavedAddressModel address) {
    return SelectedLocationResult(
      addressLine: address.addressLine,
      city: address.city,
      state: address.state,
      pincode: address.pincode,
      landmark: address.landmark,
      label: address.label,
      contactName: address.contactName,
      phone: address.phone,
      latitude: address.latitude,
      longitude: address.longitude,
      savedAddressId: address.id,
    );
  }
}

class SelectLocationArgs {
  const SelectLocationArgs({
    this.initial,
    this.title = 'Select a location',
  });

  final SelectedLocationResult? initial;
  final String title;
}
