import 'doctor_model.dart';
import '../../core/constants/phone_countries.dart';

class BloodComponentPricing {
  const BloodComponentPricing({
    required this.componentId,
    required this.componentName,
    this.priceInr = 0,
    this.governmentPriceInr,
    this.discountPriceInr,
    this.availabilityStatus = 'available',
    this.enabled = true,
  });

  final String componentId;
  final String componentName;
  final int priceInr;
  final int? governmentPriceInr;
  final int? discountPriceInr;
  final String availabilityStatus;
  final bool enabled;

  int get effectivePrice => discountPriceInr ?? priceInr;

  factory BloodComponentPricing.fromJson(Map<String, dynamic> json) {
    return BloodComponentPricing(
      componentId: json['componentId'] as String? ?? '',
      componentName: json['componentName'] as String? ?? '',
      priceInr: (json['priceInr'] as num?)?.toInt() ?? 0,
      governmentPriceInr: (json['governmentPriceInr'] as num?)?.toInt(),
      discountPriceInr: (json['discountPriceInr'] as num?)?.toInt(),
      availabilityStatus: json['availabilityStatus'] as String? ?? 'available',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class BloodBankOffer {
  const BloodBankOffer({
    required this.id,
    this.offerAvailable = false,
    this.discountType,
    this.discountValue,
    this.offerTitle,
    this.offerDescription,
    this.validFrom,
    this.validTill,
    this.applicableBloodTypes = const [],
    this.minimumOrderAmount,
    this.active = true,
  });

  final String id;
  final bool offerAvailable;
  final String? discountType;
  final num? discountValue;
  final String? offerTitle;
  final String? offerDescription;
  final DateTime? validFrom;
  final DateTime? validTill;
  final List<String> applicableBloodTypes;
  final int? minimumOrderAmount;
  final bool active;

  bool get isActiveNow {
    if (!offerAvailable || !active) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTill != null && now.isAfter(validTill!)) return false;
    return true;
  }

  factory BloodBankOffer.fromJson(Map<String, dynamic> json) {
    return BloodBankOffer(
      id: json['id'] as String? ?? '',
      offerAvailable: json['offerAvailable'] as bool? ?? false,
      discountType: json['discountType'] as String?,
      discountValue: json['discountValue'] as num?,
      offerTitle: json['offerTitle'] as String?,
      offerDescription: json['offerDescription'] as String?,
      validFrom: json['validFrom'] != null
          ? DateTime.tryParse(json['validFrom'].toString())
          : null,
      validTill: json['validTill'] != null
          ? DateTime.tryParse(json['validTill'].toString())
          : null,
      applicableBloodTypes: (json['applicableBloodTypes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toInt(),
      active: json['active'] as bool? ?? true,
    );
  }
}

class BloodInventoryEntry {
  const BloodInventoryEntry({
    required this.bloodGroup,
    this.availableUnits = 0,
    this.reservedUnits = 0,
    this.totalUnits = 0,
    this.lastUpdated,
  });

  final String bloodGroup;
  final int availableUnits;
  final int reservedUnits;
  final int totalUnits;
  final DateTime? lastUpdated;

  String get availabilityLevel {
    if (availableUnits <= 0) return 'none';
    if (availableUnits <= 3) return 'low';
    if (availableUnits <= 10) return 'medium';
    return 'high';
  }

  factory BloodInventoryEntry.fromJson(Map<String, dynamic> json) {
    return BloodInventoryEntry(
      bloodGroup: json['bloodGroup'] as String? ?? '',
      availableUnits: (json['availableUnits'] as num?)?.toInt() ?? 0,
      reservedUnits: (json['reservedUnits'] as num?)?.toInt() ?? 0,
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
    );
  }
}

class BloodReviewModel {
  const BloodReviewModel({
    required this.id,
    this.patientName,
    this.rating = 5,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String? patientName;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory BloodReviewModel.fromJson(Map<String, dynamic> json) {
    return BloodReviewModel(
      id: json['id'] as String? ?? '',
      patientName: json['patientName'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class BloodOrderModel {
  const BloodOrderModel({
    required this.id,
    required this.bloodBankId,
    this.bloodGroup,
    this.componentType,
    this.units = 1,
    this.status = 'pending',
    this.totalAmount = 0,
    this.deliveryMethod,
    this.deliveryDate,
    this.deliveryTimeSlot,
    this.estimatedDeliveryTime,
    this.createdAt,
  });

  final String id;
  final String bloodBankId;
  final String? bloodGroup;
  final String? componentType;
  final int units;
  final String status;
  final int totalAmount;
  final String? deliveryMethod;
  final DateTime? deliveryDate;
  final String? deliveryTimeSlot;
  final DateTime? estimatedDeliveryTime;
  final DateTime? createdAt;

  factory BloodOrderModel.fromJson(Map<String, dynamic> json) {
    return BloodOrderModel(
      id: json['id'] as String? ?? '',
      bloodBankId: json['bloodBankId'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String?,
      componentType: json['componentType'] as String?,
      units: (json['units'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      deliveryMethod: json['deliveryMethod'] as String?,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.tryParse(json['deliveryDate'].toString())
          : null,
      deliveryTimeSlot: json['deliveryTimeSlot'] as String?,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.tryParse(json['estimatedDeliveryTime'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class BloodBankModel {
  final String? id;
  final String? institutionName;
  final String? ownerName;
  final String? licenseNumber;
  final String? governmentRegistrationNumber;
  final String? gstNumber;
  final String? contactPerson;
  final String? email;
  final String? mobileNumber;
  final String? countryCode;
  final String? profilePicture;
  final String? logoUrl;
  final String? description;
  final String? emergencyContact;
  final String? whatsappNumber;
  final String? landlineNumber;
  final String? emailSupport;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? openingTime;
  final String? closingTime;
  final List<String>? bloodGroupsAvailable;
  final List<String>? facilities;
  final bool? hasApheresis;
  final bool? hasComponentSeparation;
  final bool? available24x7;
  final bool? emergencyBloodSupply;
  final bool? homeDeliveryAvailable;
  final bool? hospitalDeliveryAvailable;
  final bool? cashPaymentEnabled;
  final List<BloodComponentPricing>? bloodComponents;
  final List<BloodBankOffer>? offers;
  final List<String>? galleryImages;
  final List<BloodInventoryEntry>? inventory;
  final double? averageRating;
  final int? reviewCount;
  final double? distanceKm;
  final VerificationStatus? verificationStatus;

  BloodBankModel({
    this.id,
    this.institutionName,
    this.ownerName,
    this.licenseNumber,
    this.governmentRegistrationNumber,
    this.gstNumber,
    this.contactPerson,
    this.email,
    this.mobileNumber,
    this.countryCode,
    this.profilePicture,
    this.logoUrl,
    this.description,
    this.emergencyContact,
    this.whatsappNumber,
    this.landlineNumber,
    this.emailSupport,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.openingTime,
    this.closingTime,
    this.bloodGroupsAvailable,
    this.facilities,
    this.hasApheresis,
    this.hasComponentSeparation,
    this.available24x7,
    this.emergencyBloodSupply,
    this.homeDeliveryAvailable,
    this.hospitalDeliveryAvailable,
    this.cashPaymentEnabled,
    this.bloodComponents,
    this.offers,
    this.galleryImages,
    this.inventory,
    this.averageRating,
    this.reviewCount,
    this.distanceKm,
    this.verificationStatus,
  });

  String get displayName => institutionName ?? 'Blood bank';

  BloodBankOffer? get activeOffer =>
      offers?.where((o) => o.isActiveNow).cast<BloodBankOffer?>().firstOrNull;

  int? get startingPrice {
    final prices = (bloodComponents ?? [])
        .where((c) => c.enabled && c.availabilityStatus == 'available')
        .map((c) => c.effectivePrice)
        .where((p) => p > 0)
        .toList();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  bool get isOpenNow {
    if (available24x7 == true) return true;
    if (openingTime == null || closingTime == null) return true;
    final now = DateTime.now();
    final parts = openingTime!.split(':');
    final closeParts = closingTime!.split(':');
    if (parts.length < 2 || closeParts.length < 2) return true;
    final openMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final closeMins = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    final nowMins = now.hour * 60 + now.minute;
    return nowMins >= openMins && nowMins <= closeMins;
  }

  factory BloodBankModel.fromJson(Map<String, dynamic> json) {
    return BloodBankModel(
      id: json['id'] as String?,
      institutionName: json['institutionName'] as String?,
      ownerName: json['ownerName'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      governmentRegistrationNumber: json['governmentRegistrationNumber'] as String?,
      gstNumber: json['gstNumber'] as String?,
      contactPerson: json['contactPerson'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      countryCode: json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      profilePicture: json['profilePicture'] as String?,
      logoUrl: json['logoUrl'] as String?,
      description: json['description'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      landlineNumber: json['landlineNumber'] as String?,
      emailSupport: json['emailSupport'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      bloodGroupsAvailable: (json['bloodGroupsAvailable'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      facilities: (json['facilities'] as List?)?.map((e) => e.toString()).toList(),
      hasApheresis: json['hasApheresis'] as bool?,
      hasComponentSeparation: json['hasComponentSeparation'] as bool?,
      available24x7: json['available24x7'] as bool?,
      emergencyBloodSupply: json['emergencyBloodSupply'] as bool?,
      homeDeliveryAvailable: json['homeDeliveryAvailable'] as bool?,
      hospitalDeliveryAvailable: json['hospitalDeliveryAvailable'] as bool?,
      cashPaymentEnabled: json['cashPaymentEnabled'] as bool?,
      bloodComponents: (json['bloodComponents'] as List?)
          ?.map((e) => BloodComponentPricing.fromJson(e as Map<String, dynamic>))
          .toList(),
      offers: (json['offers'] as List?)
          ?.map((e) => BloodBankOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
      galleryImages: (json['galleryImages'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      inventory: (json['inventory'] as List?)
          ?.map((e) => BloodInventoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      verificationStatus: _parseStatus(json['verificationStatus'] as String?),
    );
  }

  BloodBankModel copyWith({
    String? id,
    String? institutionName,
    String? ownerName,
    String? licenseNumber,
    String? governmentRegistrationNumber,
    String? gstNumber,
    String? contactPerson,
    String? email,
    String? mobileNumber,
    String? countryCode,
    String? profilePicture,
    String? logoUrl,
    String? description,
    String? emergencyContact,
    String? whatsappNumber,
    String? landlineNumber,
    String? emailSupport,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? openingTime,
    String? closingTime,
    List<String>? bloodGroupsAvailable,
    List<String>? facilities,
    bool? hasApheresis,
    bool? hasComponentSeparation,
    bool? available24x7,
    bool? emergencyBloodSupply,
    bool? homeDeliveryAvailable,
    bool? hospitalDeliveryAvailable,
    bool? cashPaymentEnabled,
    List<BloodComponentPricing>? bloodComponents,
    List<BloodBankOffer>? offers,
    List<String>? galleryImages,
    List<BloodInventoryEntry>? inventory,
    double? averageRating,
    int? reviewCount,
    double? distanceKm,
    VerificationStatus? verificationStatus,
  }) {
    return BloodBankModel(
      id: id ?? this.id,
      institutionName: institutionName ?? this.institutionName,
      ownerName: ownerName ?? this.ownerName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      governmentRegistrationNumber:
          governmentRegistrationNumber ?? this.governmentRegistrationNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      countryCode: countryCode ?? this.countryCode,
      profilePicture: profilePicture ?? this.profilePicture,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      landlineNumber: landlineNumber ?? this.landlineNumber,
      emailSupport: emailSupport ?? this.emailSupport,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      bloodGroupsAvailable: bloodGroupsAvailable ?? this.bloodGroupsAvailable,
      facilities: facilities ?? this.facilities,
      hasApheresis: hasApheresis ?? this.hasApheresis,
      hasComponentSeparation:
          hasComponentSeparation ?? this.hasComponentSeparation,
      available24x7: available24x7 ?? this.available24x7,
      emergencyBloodSupply: emergencyBloodSupply ?? this.emergencyBloodSupply,
      homeDeliveryAvailable:
          homeDeliveryAvailable ?? this.homeDeliveryAvailable,
      hospitalDeliveryAvailable:
          hospitalDeliveryAvailable ?? this.hospitalDeliveryAvailable,
      cashPaymentEnabled: cashPaymentEnabled ?? this.cashPaymentEnabled,
      bloodComponents: bloodComponents ?? this.bloodComponents,
      offers: offers ?? this.offers,
      galleryImages: galleryImages ?? this.galleryImages,
      inventory: inventory ?? this.inventory,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (institutionName != null) 'institutionName': institutionName,
      if (ownerName != null) 'ownerName': ownerName,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (countryCode != null) 'countryCode': countryCode,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (bloodGroupsAvailable != null)
        'bloodGroupsAvailable': bloodGroupsAvailable,
      if (facilities != null) 'facilities': facilities,
      if (hasApheresis != null) 'hasApheresis': hasApheresis,
      if (hasComponentSeparation != null)
        'hasComponentSeparation': hasComponentSeparation,
      if (available24x7 != null) 'available24x7': available24x7,
      if (emergencyBloodSupply != null) 'emergencyBloodSupply': emergencyBloodSupply,
      if (homeDeliveryAvailable != null)
        'homeDeliveryAvailable': homeDeliveryAvailable,
    };
  }

  static VerificationStatus? _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      default:
        return VerificationStatus.pending;
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
