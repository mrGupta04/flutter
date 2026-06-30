import 'doctor_model.dart';
import '../../core/constants/phone_countries.dart';

class LabOfferedTest {
  const LabOfferedTest({
    required this.testId,
    required this.testName,
    required this.categoryId,
    required this.priceInr,
    this.discountedPriceInr,
    this.reportDeliveryTime,
    this.homeCollectionAvailable = true,
    this.onsiteCollectionAvailable = true,
    this.preparationInstructions,
    this.description,
    this.enabled = true,
  });

  final String testId;
  final String testName;
  final String categoryId;
  final int priceInr;
  final int? discountedPriceInr;
  final String? reportDeliveryTime;
  final bool homeCollectionAvailable;
  final bool onsiteCollectionAvailable;
  final String? preparationInstructions;
  final String? description;
  final bool enabled;

  factory LabOfferedTest.fromJson(Map<String, dynamic> json) {
    return LabOfferedTest(
      testId: json['testId'] as String? ?? '',
      testName: json['testName'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      priceInr: (json['priceInr'] as num?)?.toInt() ?? 0,
      discountedPriceInr: (json['discountedPriceInr'] as num?)?.toInt(),
      reportDeliveryTime: json['reportDeliveryTime'] as String?,
      homeCollectionAvailable: json['homeCollectionAvailable'] as bool? ?? true,
      onsiteCollectionAvailable:
          json['onsiteCollectionAvailable'] as bool? ?? true,
      preparationInstructions: json['preparationInstructions'] as String?,
      description: json['description'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'testName': testName,
        'categoryId': categoryId,
        'priceInr': priceInr,
        if (discountedPriceInr != null) 'discountedPriceInr': discountedPriceInr,
        if (reportDeliveryTime != null) 'reportDeliveryTime': reportDeliveryTime,
        'homeCollectionAvailable': homeCollectionAvailable,
        'onsiteCollectionAvailable': onsiteCollectionAvailable,
        if (preparationInstructions != null)
          'preparationInstructions': preparationInstructions,
        if (description != null) 'description': description,
        'enabled': enabled,
      };

  LabOfferedTest copyWith({
    String? testId,
    String? testName,
    String? categoryId,
    int? priceInr,
    int? discountedPriceInr,
    String? reportDeliveryTime,
    bool? homeCollectionAvailable,
    bool? onsiteCollectionAvailable,
    String? preparationInstructions,
    String? description,
    bool? enabled,
  }) {
    return LabOfferedTest(
      testId: testId ?? this.testId,
      testName: testName ?? this.testName,
      categoryId: categoryId ?? this.categoryId,
      priceInr: priceInr ?? this.priceInr,
      discountedPriceInr: discountedPriceInr ?? this.discountedPriceInr,
      reportDeliveryTime: reportDeliveryTime ?? this.reportDeliveryTime,
      homeCollectionAvailable:
          homeCollectionAvailable ?? this.homeCollectionAvailable,
      onsiteCollectionAvailable:
          onsiteCollectionAvailable ?? this.onsiteCollectionAvailable,
      preparationInstructions:
          preparationInstructions ?? this.preparationInstructions,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
    );
  }
}

class LabBranch {
  const LabBranch({
    required this.id,
    this.name,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;

  factory LabBranch.fromJson(Map<String, dynamic> json) => LabBranch(
        id: json['id'] as String? ?? '',
        name: json['name'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}

class LabHomeVisitSlot {
  const LabHomeVisitSlot({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  final String day;
  final String startTime;
  final String endTime;

  factory LabHomeVisitSlot.fromJson(Map<String, dynamic> json) =>
      LabHomeVisitSlot(
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

class LabDocument {
  const LabDocument({
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

  factory LabDocument.fromJson(Map<String, dynamic> json) => LabDocument(
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

class LabModel {
  const LabModel({
    this.id,
    this.labName,
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
    this.accreditation,
    this.operatingHours,
    this.homeCollectionAvailable,
    this.available24x7,
    this.offeredTests,
    this.branches,
    this.serviceablePincodes,
    this.homeVisitSlots,
    this.labImages,
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
  final String? labName;
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
  final String? accreditation;
  final String? operatingHours;
  final bool? homeCollectionAvailable;
  final bool? available24x7;
  final List<LabOfferedTest>? offeredTests;
  final List<LabBranch>? branches;
  final List<String>? serviceablePincodes;
  final List<LabHomeVisitSlot>? homeVisitSlots;
  final List<String>? labImages;
  final List<LabDocument>? documents;
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

  String get displayName => labName ?? 'Diagnostic lab';

  LabOfferedTest? offeredTest(String testId) {
    for (final t in offeredTests ?? const []) {
      if (t.testId == testId && t.enabled) return t;
    }
    return null;
  }

  factory LabModel.fromJson(Map<String, dynamic> json) {
    return LabModel(
      id: json['id'] as String?,
      labName: json['labName'] as String?,
      ownerName: json['ownerName'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      countryCode: json['countryCode'] as String? ?? PhoneCountries.defaultDialCode,
      profilePicture: json['profilePicture'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      gstNumber: json['gstNumber'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      accreditation: json['accreditation'] as String?,
      operatingHours: json['operatingHours'] as String?,
      homeCollectionAvailable: json['homeCollectionAvailable'] as bool?,
      available24x7: json['available24x7'] as bool?,
      offeredTests: (json['offeredTests'] as List?)
          ?.map((e) => LabOfferedTest.fromJson(e as Map<String, dynamic>))
          .toList(),
      branches: (json['branches'] as List?)
          ?.map((e) => LabBranch.fromJson(e as Map<String, dynamic>))
          .toList(),
      serviceablePincodes: (json['serviceablePincodes'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      homeVisitSlots: (json['homeVisitSlots'] as List?)
          ?.map((e) => LabHomeVisitSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      labImages: (json['labImages'] as List?)?.map((e) => e.toString()).toList(),
      documents: (json['documents'] as List?)
          ?.map((e) => LabDocument.fromJson(e as Map<String, dynamic>))
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
        if (labName != null) 'labName': labName,
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
        if (accreditation != null) 'accreditation': accreditation,
        if (operatingHours != null) 'operatingHours': operatingHours,
        if (homeCollectionAvailable != null)
          'homeCollectionAvailable': homeCollectionAvailable,
        if (available24x7 != null) 'available24x7': available24x7,
        if (offeredTests != null)
          'offeredTests': offeredTests!.map((e) => e.toJson()).toList(),
        if (branches != null)
          'branches': branches!.map((e) => e.toJson()).toList(),
        if (serviceablePincodes != null) 'serviceablePincodes': serviceablePincodes,
        if (homeVisitSlots != null)
          'homeVisitSlots': homeVisitSlots!.map((e) => e.toJson()).toList(),
        if (labImages != null) 'labImages': labImages,
        if (documents != null)
          'documents': documents!.map((e) => e.toJson()).toList(),
      };

  static VerificationStatus? _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
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

  LabModel copyWith({
    String? id,
    String? labName,
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
    String? accreditation,
    String? operatingHours,
    bool? homeCollectionAvailable,
    bool? available24x7,
    List<LabOfferedTest>? offeredTests,
    List<LabBranch>? branches,
    List<String>? serviceablePincodes,
    List<LabHomeVisitSlot>? homeVisitSlots,
    List<String>? labImages,
    List<LabDocument>? documents,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    String? documentRequestNote,
    bool? isApproved,
    String? approvalNotes,
  }) {
    return LabModel(
      id: id ?? this.id,
      labName: labName ?? this.labName,
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
      accreditation: accreditation ?? this.accreditation,
      operatingHours: operatingHours ?? this.operatingHours,
      homeCollectionAvailable:
          homeCollectionAvailable ?? this.homeCollectionAvailable,
      available24x7: available24x7 ?? this.available24x7,
      offeredTests: offeredTests ?? this.offeredTests,
      branches: branches ?? this.branches,
      serviceablePincodes: serviceablePincodes ?? this.serviceablePincodes,
      homeVisitSlots: homeVisitSlots ?? this.homeVisitSlots,
      labImages: labImages ?? this.labImages,
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
