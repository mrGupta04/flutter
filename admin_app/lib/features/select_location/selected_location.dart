class SavedPlaceModel {
  const SavedPlaceModel({
    required this.id,
    required this.addressLine,
    this.label = 'Home',
    this.city,
    this.state,
    this.pincode,
    this.landmark,
    this.contactName,
    this.phone,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String addressLine;
  final String? city;
  final String? state;
  final String? pincode;
  final String? landmark;
  final String? contactName;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  String get displayLine {
    final parts = [
      addressLine,
      if (landmark != null && landmark!.trim().isNotEmpty) landmark!.trim(),
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (pincode != null && pincode!.isNotEmpty) pincode!,
    ];
    return parts.join(', ');
  }

  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    return SavedPlaceModel(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String? ?? 'Home',
      addressLine: json['addressLine'] as String? ?? '',
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      landmark: json['landmark'] as String?,
      contactName: json['contactName'] as String?,
      phone: json['phone'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'addressLine': addressLine,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (landmark != null) 'landmark': landmark,
        if (contactName != null) 'contactName': contactName,
        if (phone != null) 'phone': phone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isDefault': isDefault,
      };
}

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

  factory SelectedLocationResult.fromSaved(SavedPlaceModel address) {
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
