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

  Map<String, dynamic> toJson() => {
        'componentId': componentId,
        'componentName': componentName,
        'priceInr': priceInr,
        if (governmentPriceInr != null) 'governmentPriceInr': governmentPriceInr,
        if (discountPriceInr != null) 'discountPriceInr': discountPriceInr,
        'availabilityStatus': availabilityStatus,
        'enabled': enabled,
      };

  BloodComponentPricing copyWith({
    int? priceInr,
    int? governmentPriceInr,
    int? discountPriceInr,
    String? availabilityStatus,
    bool? enabled,
  }) {
    return BloodComponentPricing(
      componentId: componentId,
      componentName: componentName,
      priceInr: priceInr ?? this.priceInr,
      governmentPriceInr: governmentPriceInr ?? this.governmentPriceInr,
      discountPriceInr: discountPriceInr ?? this.discountPriceInr,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      enabled: enabled ?? this.enabled,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'offerAvailable': offerAvailable,
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue,
        if (offerTitle != null) 'offerTitle': offerTitle,
        if (offerDescription != null) 'offerDescription': offerDescription,
        if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
        if (validTill != null) 'validTill': validTill!.toIso8601String(),
        if (applicableBloodTypes.isNotEmpty)
          'applicableBloodTypes': applicableBloodTypes,
        if (minimumOrderAmount != null) 'minimumOrderAmount': minimumOrderAmount,
        'active': active,
      };
}

class BloodBankDocument {
  const BloodBankDocument({
    required this.id,
    required this.type,
    required this.label,
    required this.url,
    this.verificationStatus = 'pending',
    this.rejectionReason,
  });

  final String id;
  final String type;
  final String label;
  final String url;
  final String verificationStatus;
  final String? rejectionReason;

  factory BloodBankDocument.fromJson(Map<String, dynamic> json) {
    return BloodBankDocument(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      url: json['url'] as String? ?? '',
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
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
  final List<BloodBankDocument>? documents;
  final VerificationStatus? verificationStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isApproved;
  final String? approvalNotes;

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
    this.documents,
    this.verificationStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.isApproved,
    this.approvalNotes,
  });

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
      galleryImages: (json['galleryImages'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      documents: (json['documents'] as List?)
          ?.map((e) => BloodBankDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      verificationStatus: json['isApproved'] == true
          ? VerificationStatus.verified
          : _parseStatus(json['verificationStatus'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isApproved: json['isApproved'] as bool?,
      approvalNotes: json['approvalNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (institutionName != null) 'institutionName': institutionName,
      if (ownerName != null) 'ownerName': ownerName,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (governmentRegistrationNumber != null)
        'governmentRegistrationNumber': governmentRegistrationNumber,
      if (gstNumber != null) 'gstNumber': gstNumber,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (countryCode != null) 'countryCode': countryCode,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (description != null) 'description': description,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (whatsappNumber != null) 'whatsappNumber': whatsappNumber,
      if (landlineNumber != null) 'landlineNumber': landlineNumber,
      if (emailSupport != null) 'emailSupport': emailSupport,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (openingTime != null) 'openingTime': openingTime,
      if (closingTime != null) 'closingTime': closingTime,
      if (bloodGroupsAvailable != null)
        'bloodGroupsAvailable': bloodGroupsAvailable,
      if (facilities != null) 'facilities': facilities,
      if (hasApheresis != null) 'hasApheresis': hasApheresis,
      if (hasComponentSeparation != null)
        'hasComponentSeparation': hasComponentSeparation,
      if (available24x7 != null) 'available24x7': available24x7,
      if (emergencyBloodSupply != null) 'emergencyBloodSupply': emergencyBloodSupply,
      if (homeDeliveryAvailable != null) 'homeDeliveryAvailable': homeDeliveryAvailable,
      if (hospitalDeliveryAvailable != null)
        'hospitalDeliveryAvailable': hospitalDeliveryAvailable,
      if (cashPaymentEnabled != null) 'cashPaymentEnabled': cashPaymentEnabled,
      if (bloodComponents != null)
        'bloodComponents': bloodComponents!.map((c) => c.toJson()).toList(),
      if (offers != null) 'offers': offers!.map((o) => o.toJson()).toList(),
      if (galleryImages != null) 'galleryImages': galleryImages,
    };
  }

  static VerificationStatus? _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'under_review':
      case 'verifier_approved':
        return VerificationStatus.underReview;
      default:
        return VerificationStatus.pending;
    }
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
    List<BloodBankDocument>? documents,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    String? approvalNotes,
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
      homeDeliveryAvailable: homeDeliveryAvailable ?? this.homeDeliveryAvailable,
      hospitalDeliveryAvailable:
          hospitalDeliveryAvailable ?? this.hospitalDeliveryAvailable,
      cashPaymentEnabled: cashPaymentEnabled ?? this.cashPaymentEnabled,
      bloodComponents: bloodComponents ?? this.bloodComponents,
      offers: offers ?? this.offers,
      galleryImages: galleryImages ?? this.galleryImages,
      documents: documents ?? this.documents,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      approvalNotes: approvalNotes ?? this.approvalNotes,
    );
  }
}
