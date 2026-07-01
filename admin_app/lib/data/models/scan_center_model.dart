import 'doctor_model.dart';
import '../../core/constants/phone_countries.dart';

class ScanOfferedProcedure {
  const ScanOfferedProcedure({
    required this.scanId,
    required this.scanName,
    required this.categoryId,
    required this.priceInr,
    this.discountedPriceInr,
    this.reportDeliveryTime,
    this.preparationInstructions,
    this.description,
    this.fastingRequired = false,
    this.homeVisitAvailable = false,
    this.onsiteOnly = true,
    this.reportFormat = 'digital',
    this.availabilityStatus = 'available',
    this.prescriptionRequired = true,
    this.images = const [],
    this.enabled = true,
  });

  final String scanId;
  final String scanName;
  final String categoryId;
  final int priceInr;
  final int? discountedPriceInr;
  final String? reportDeliveryTime;
  final String? preparationInstructions;
  final String? description;
  final bool fastingRequired;
  final bool homeVisitAvailable;
  final bool onsiteOnly;
  final String reportFormat;
  final String availabilityStatus;
  final bool prescriptionRequired;
  final List<String> images;
  final bool enabled;

  int get effectivePrice => discountedPriceInr ?? priceInr;

  factory ScanOfferedProcedure.fromJson(Map<String, dynamic> json) {
    return ScanOfferedProcedure(
      scanId: json['scanId'] as String? ?? '',
      scanName: json['scanName'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      priceInr: (json['priceInr'] as num?)?.toInt() ?? 0,
      discountedPriceInr: (json['discountedPriceInr'] as num?)?.toInt(),
      reportDeliveryTime: json['reportDeliveryTime'] as String?,
      preparationInstructions: json['preparationInstructions'] as String?,
      description: json['description'] as String?,
      fastingRequired: json['fastingRequired'] as bool? ?? false,
      homeVisitAvailable: json['homeVisitAvailable'] as bool? ?? false,
      onsiteOnly: json['onsiteOnly'] as bool? ?? true,
      reportFormat: json['reportFormat'] as String? ?? 'digital',
      availabilityStatus: json['availabilityStatus'] as String? ?? 'available',
      prescriptionRequired: json['prescriptionRequired'] as bool? ?? true,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scanId': scanId,
        'scanName': scanName,
        'categoryId': categoryId,
        'priceInr': priceInr,
        if (discountedPriceInr != null) 'discountedPriceInr': discountedPriceInr,
        if (reportDeliveryTime != null) 'reportDeliveryTime': reportDeliveryTime,
        if (preparationInstructions != null)
          'preparationInstructions': preparationInstructions,
        if (description != null) 'description': description,
        'fastingRequired': fastingRequired,
        'homeVisitAvailable': homeVisitAvailable,
        'onsiteOnly': onsiteOnly,
        'reportFormat': reportFormat,
        'availabilityStatus': availabilityStatus,
        'prescriptionRequired': prescriptionRequired,
        if (images.isNotEmpty) 'images': images,
        'enabled': enabled,
      };

  ScanOfferedProcedure copyWith({
    String? scanId,
    String? scanName,
    String? categoryId,
    int? priceInr,
    int? discountedPriceInr,
    String? reportDeliveryTime,
    String? preparationInstructions,
    String? description,
    bool? fastingRequired,
    bool? homeVisitAvailable,
    bool? onsiteOnly,
    String? reportFormat,
    String? availabilityStatus,
    bool? prescriptionRequired,
    List<String>? images,
    bool? enabled,
  }) {
    return ScanOfferedProcedure(
      scanId: scanId ?? this.scanId,
      scanName: scanName ?? this.scanName,
      categoryId: categoryId ?? this.categoryId,
      priceInr: priceInr ?? this.priceInr,
      discountedPriceInr: discountedPriceInr ?? this.discountedPriceInr,
      reportDeliveryTime: reportDeliveryTime ?? this.reportDeliveryTime,
      preparationInstructions:
          preparationInstructions ?? this.preparationInstructions,
      description: description ?? this.description,
      fastingRequired: fastingRequired ?? this.fastingRequired,
      homeVisitAvailable: homeVisitAvailable ?? this.homeVisitAvailable,
      onsiteOnly: onsiteOnly ?? this.onsiteOnly,
      reportFormat: reportFormat ?? this.reportFormat,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      prescriptionRequired: prescriptionRequired ?? this.prescriptionRequired,
      images: images ?? this.images,
      enabled: enabled ?? this.enabled,
    );
  }
}

class ScanCenterOffer {
  const ScanCenterOffer({
    required this.id,
    this.offerAvailable = false,
    this.discountType,
    this.discountValue,
    this.offerTitle,
    this.offerDescription,
    this.validFrom,
    this.validTill,
    this.minimumBookingAmount,
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
  final int? minimumBookingAmount;
  final bool active;

  bool get isActiveNow {
    if (!offerAvailable || !active) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTill != null && now.isAfter(validTill!)) return false;
    return true;
  }

  factory ScanCenterOffer.fromJson(Map<String, dynamic> json) {
    return ScanCenterOffer(
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
      minimumBookingAmount: (json['minimumBookingAmount'] as num?)?.toInt(),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'offerAvailable': offerAvailable,
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue,
        if (offerTitle != null) 'offerTitle': offerTitle,
        if (offerDescription != null) 'offerDescription': offerDescription,
        if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
        if (validTill != null) 'validTill': validTill!.toIso8601String(),
        if (minimumBookingAmount != null)
          'minimumBookingAmount': minimumBookingAmount,
        'active': active,
      };
}

class ScanAppointmentSlot {
  const ScanAppointmentSlot({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  final String day;
  final String startTime;
  final String endTime;

  factory ScanAppointmentSlot.fromJson(Map<String, dynamic> json) =>
      ScanAppointmentSlot(
        day: json['day'] as String? ?? '',
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
      };
}

class ScanCenterDocument {
  const ScanCenterDocument({
    required this.id,
    required this.type,
    required this.label,
    required this.url,
    this.verificationStatus,
    this.rejectionReason,
  });

  final String id;
  final String type;
  final String label;
  final String url;
  final String? verificationStatus;
  final String? rejectionReason;

  factory ScanCenterDocument.fromJson(Map<String, dynamic> json) =>
      ScanCenterDocument(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
        verificationStatus: json['verificationStatus'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'url': url,
        if (verificationStatus != null) 'verificationStatus': verificationStatus,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };
}

class ScanCenterModel {
  const ScanCenterModel({
    this.id,
    this.centerName,
    this.ownerName,
    this.email,
    this.mobileNumber,
    this.countryCode,
    this.profilePicture,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.gstNumber,
    this.licenseNumber,
    this.operatingHours,
    this.homeVisitAvailable,
    this.available24x7,
    this.cashPaymentEnabled,
    this.offeredScans,
    this.offers,
    this.appointmentSlots,
    this.centerImages,
    this.documents,
    this.averageRating,
    this.reviewCount,
    this.verificationStatus,
    this.rejectionReason,
    this.documentRequestNote,
    this.isApproved,
    this.approvalNotes,
    this.distanceKm,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? centerName;
  final String? ownerName;
  final String? email;
  final String? mobileNumber;
  final String? countryCode;
  final String? profilePicture;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? gstNumber;
  final String? licenseNumber;
  final String? operatingHours;
  final bool? homeVisitAvailable;
  final bool? available24x7;
  final bool? cashPaymentEnabled;
  final List<ScanOfferedProcedure>? offeredScans;
  final List<ScanCenterOffer>? offers;
  final List<ScanAppointmentSlot>? appointmentSlots;
  final List<String>? centerImages;
  final List<ScanCenterDocument>? documents;
  final double? averageRating;
  final int? reviewCount;
  final VerificationStatus? verificationStatus;
  final String? rejectionReason;
  final String? documentRequestNote;
  final bool? isApproved;
  final String? approvalNotes;
  final double? distanceKm;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => centerName ?? 'Imaging center';

  ScanOfferedProcedure? offeredScan(String scanId) {
    for (final scan in offeredScans ?? const []) {
      if (scan.scanId == scanId && scan.enabled) return scan;
    }
    return null;
  }

  ScanCenterOffer? get activeOffer {
    for (final offer in offers ?? const []) {
      if (offer.isActiveNow) return offer;
    }
    return null;
  }

  factory ScanCenterModel.fromJson(Map<String, dynamic> json) {
    return ScanCenterModel(
      id: json['id'] as String?,
      centerName: json['centerName'] as String?,
      ownerName: json['ownerName'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      countryCode:
          json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      profilePicture: json['profilePicture'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      gstNumber: json['gstNumber'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      operatingHours: json['operatingHours'] as String?,
      homeVisitAvailable: json['homeVisitAvailable'] as bool?,
      available24x7: json['available24x7'] as bool?,
      cashPaymentEnabled: json['cashPaymentEnabled'] as bool?,
      offeredScans: (json['offeredScans'] as List?)
          ?.map((e) => ScanOfferedProcedure.fromJson(e as Map<String, dynamic>))
          .toList(),
      offers: (json['offers'] as List?)
          ?.map((e) => ScanCenterOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
      appointmentSlots: (json['appointmentSlots'] as List?)
          ?.map((e) => ScanAppointmentSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      centerImages:
          (json['centerImages'] as List?)?.map((e) => e.toString()).toList(),
      documents: (json['documents'] as List?)
          ?.map((e) => ScanCenterDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      verificationStatus: json['isApproved'] == true
          ? VerificationStatus.verified
          : _parseStatus(json['verificationStatus'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      documentRequestNote: json['documentRequestNote'] as String?,
      isApproved: json['isApproved'] as bool?,
      approvalNotes: json['approvalNotes'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (centerName != null) 'centerName': centerName,
        if (ownerName != null) 'ownerName': ownerName,
        if (email != null) 'email': email,
        if (mobileNumber != null) 'mobileNumber': mobileNumber,
        if (countryCode != null) 'countryCode': countryCode,
        if (profilePicture != null) 'profilePicture': profilePicture,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (gstNumber != null) 'gstNumber': gstNumber,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        if (operatingHours != null) 'operatingHours': operatingHours,
        if (homeVisitAvailable != null) 'homeVisitAvailable': homeVisitAvailable,
        if (available24x7 != null) 'available24x7': available24x7,
        if (cashPaymentEnabled != null) 'cashPaymentEnabled': cashPaymentEnabled,
        if (offeredScans != null)
          'offeredScans': offeredScans!.map((e) => e.toJson()).toList(),
        if (offers != null) 'offers': offers!.map((e) => e.toJson()).toList(),
        if (appointmentSlots != null)
          'appointmentSlots':
              appointmentSlots!.map((e) => e.toJson()).toList(),
        if (centerImages != null) 'centerImages': centerImages,
        if (documents != null)
          'documents': documents!.map((e) => e.toJson()).toList(),
      };

  static VerificationStatus? _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
      case 'suspended':
        return VerificationStatus.rejected;
      case 'under_review':
      case 'verifier_approved':
        return VerificationStatus.underReview;
      case 'pending':
      default:
        return VerificationStatus.pending;
    }
  }

  ScanCenterModel copyWith({
    String? id,
    String? centerName,
    String? ownerName,
    String? email,
    String? mobileNumber,
    String? profilePicture,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? gstNumber,
    String? licenseNumber,
    String? operatingHours,
    bool? homeVisitAvailable,
    bool? available24x7,
    bool? cashPaymentEnabled,
    List<ScanOfferedProcedure>? offeredScans,
    List<ScanCenterOffer>? offers,
    List<ScanAppointmentSlot>? appointmentSlots,
    List<String>? centerImages,
    List<ScanCenterDocument>? documents,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    String? documentRequestNote,
    bool? isApproved,
    String? approvalNotes,
  }) {
    return ScanCenterModel(
      id: id ?? this.id,
      centerName: centerName ?? this.centerName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      countryCode: countryCode,
      profilePicture: profilePicture ?? this.profilePicture,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gstNumber: gstNumber ?? this.gstNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      operatingHours: operatingHours ?? this.operatingHours,
      homeVisitAvailable: homeVisitAvailable ?? this.homeVisitAvailable,
      available24x7: available24x7 ?? this.available24x7,
      cashPaymentEnabled: cashPaymentEnabled ?? this.cashPaymentEnabled,
      offeredScans: offeredScans ?? this.offeredScans,
      offers: offers ?? this.offers,
      appointmentSlots: appointmentSlots ?? this.appointmentSlots,
      centerImages: centerImages ?? this.centerImages,
      documents: documents ?? this.documents,
      averageRating: averageRating,
      reviewCount: reviewCount,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documentRequestNote: documentRequestNote ?? this.documentRequestNote,
      isApproved: isApproved ?? this.isApproved,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      distanceKm: distanceKm,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
