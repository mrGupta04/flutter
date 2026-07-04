/// Registration constants for laboratory onboarding.
import '../../../data/models/lab_model.dart';

class LabRegistrationConstants {
  LabRegistrationConstants._();

  static const labTypes = [
    'Independent Lab',
    'Diagnostic Center',
    'Hospital Lab',
    'Imaging & Diagnostic Center',
  ];

  static const sampleTypes = [
    'Blood',
    'Urine',
    'Stool',
    'Saliva',
    'Swab',
    'Semen',
    'Tissue',
  ];

  static const staffRoles = [
    'Pathologist',
    'Lab Technician',
    'Phlebotomist',
    'Receptionist',
    'Manager',
  ];

  static const weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const facilities = [
    'Home Sample Collection',
    'Walk-in Sample Collection',
    'Corporate Health Checkups',
    'Senior Citizen Collection',
    'Emergency Collection',
    'Digital Reports',
    'Printed Reports',
    'WhatsApp Reports',
    'Email Reports',
    'Express Reports',
    'Wheelchair Access',
    'Parking',
    'Waiting Lounge',
    'Air Conditioned',
    'Pharmacy Available',
  ];

  static const testCategories = [
    'Blood Tests',
    'Urine Tests',
    'Stool Tests',
    'Hormone Tests',
    'Allergy Tests',
    'Diabetes Tests',
    'Thyroid Tests',
    'Vitamin Tests',
    'Lipid Profile',
    'Liver Function Test',
    'Kidney Function Test',
    'Cardiac Tests',
    'Cancer Screening',
    'Pregnancy Tests',
    'Fertility Tests',
    'Infectious Disease Tests',
    'COVID Tests',
    'Dengue Tests',
    'Malaria Tests',
    'Genetic Tests',
    'Pathology Tests',
  ];

  static const imagingServices = [
    'MRI',
    'CT Scan',
    'X-Ray',
    'Ultrasound',
    'Mammography',
    'PET Scan',
    'ECG',
    'Echo',
    'TMT',
    'EEG',
    'EMG',
    'Pulmonary Function Test',
  ];

  static const requiredDocuments = [
    ('registration_certificate', 'Registration Certificate'),
    ('owner_id', 'Owner ID Proof'),
    ('address_proof', 'Address Proof'),
    ('nabl_certificate', 'NABL Certificate (Optional)'),
    ('gst_certificate', 'GST Certificate (Optional)'),
    ('pan_card', 'PAN Card'),
    ('bank_details', 'Bank Account Details'),
    ('cancelled_cheque', 'Cancelled Cheque'),
  ];
}

/// Extended registration payload merged with [LabModel.toJson] on submit.
class LabRegistrationExtras {
  const LabRegistrationExtras({
    this.coverImage,
    this.labType,
    this.yearEstablished,
    this.registrationNumber,
    this.nablAccreditationNumber,
    this.otherCertifications,
    this.buildingName,
    this.street,
    this.area,
    this.landmark,
    this.openingTime,
    this.closingTime,
    this.workingDays = const [],
    this.emergencyServiceAvailable = false,
    this.facilities = const [],
    this.supportedCategories = const [],
    this.healthPackages = const [],
    this.offeredScans = const [],
    this.staffMembers = const [],
    this.bankDetails,
    this.serviceCities = const [],
    this.serviceAreas = const [],
    this.homeCollectionRadiusKm,
  });

  final String? coverImage;
  final String? labType;
  final int? yearEstablished;
  final String? registrationNumber;
  final String? nablAccreditationNumber;
  final String? otherCertifications;
  final String? buildingName;
  final String? street;
  final String? area;
  final String? landmark;
  final String? openingTime;
  final String? closingTime;
  final List<LabWorkingDay> workingDays;
  final bool emergencyServiceAvailable;
  final List<String> facilities;
  final List<String> supportedCategories;
  final List<LabHealthPackageReg> healthPackages;
  final List<LabOfferedScanReg> offeredScans;
  final List<LabStaffMemberReg> staffMembers;
  final LabBankDetailsReg? bankDetails;
  final List<String> serviceCities;
  final List<String> serviceAreas;
  final double? homeCollectionRadiusKm;

  Map<String, dynamic> toJson() => {
        if (coverImage != null) 'coverImage': coverImage,
        if (labType != null) 'labType': labType,
        if (yearEstablished != null) 'yearEstablished': yearEstablished,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (nablAccreditationNumber != null)
          'nablAccreditationNumber': nablAccreditationNumber,
        if (otherCertifications != null) 'otherCertifications': otherCertifications,
        if (buildingName != null) 'buildingName': buildingName,
        if (street != null) 'street': street,
        if (area != null) 'area': area,
        if (landmark != null) 'landmark': landmark,
        if (openingTime != null) 'openingTime': openingTime,
        if (closingTime != null) 'closingTime': closingTime,
        if (workingDays.isNotEmpty)
          'workingDays': workingDays.map((e) => e.toJson()).toList(),
        'emergencyServiceAvailable': emergencyServiceAvailable,
        if (facilities.isNotEmpty) 'facilities': facilities,
        if (supportedCategories.isNotEmpty)
          'supportedCategories': supportedCategories,
        if (healthPackages.isNotEmpty)
          'healthPackages': healthPackages.map((e) => e.toJson()).toList(),
        if (offeredScans.isNotEmpty)
          'offeredScans': offeredScans.map((e) => e.toJson()).toList(),
        if (staffMembers.isNotEmpty)
          'staffMembers': staffMembers.map((e) => e.toJson()).toList(),
        if (bankDetails != null) 'bankDetails': bankDetails!.toJson(),
        if (serviceCities.isNotEmpty) 'serviceCities': serviceCities,
        if (serviceAreas.isNotEmpty) 'serviceAreas': serviceAreas,
        if (homeCollectionRadiusKm != null)
          'homeCollectionRadiusKm': homeCollectionRadiusKm,
      };
}

class LabWorkingDay {
  const LabWorkingDay({
    required this.day,
    this.isOpen = true,
    this.openingTime,
    this.closingTime,
  });

  final String day;
  final bool isOpen;
  final String? openingTime;
  final String? closingTime;

  Map<String, dynamic> toJson() => {
        'day': day,
        'isOpen': isOpen,
        if (openingTime != null) 'openingTime': openingTime,
        if (closingTime != null) 'closingTime': closingTime,
      };
}

class LabHealthPackageReg {
  const LabHealthPackageReg({
    required this.id,
    required this.name,
    required this.testIds,
    required this.originalPriceInr,
    required this.discountedPriceInr,
    this.description,
    this.reportDeliveryTime,
    this.homeCollectionAvailable = true,
    this.isPopular = false,
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final List<String> testIds;
  final int originalPriceInr;
  final int discountedPriceInr;
  final String? description;
  final String? reportDeliveryTime;
  final bool homeCollectionAvailable;
  final bool isPopular;
  final bool isRecommended;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'testIds': testIds,
        'originalPriceInr': originalPriceInr,
        'discountedPriceInr': discountedPriceInr,
        if (description != null) 'description': description,
        if (reportDeliveryTime != null) 'reportDeliveryTime': reportDeliveryTime,
        'homeCollectionAvailable': homeCollectionAvailable,
        'isPopular': isPopular,
        'isRecommended': isRecommended,
        'enabled': true,
      };
}

class LabOfferedScanReg {
  const LabOfferedScanReg({
    required this.id,
    required this.scanName,
    required this.priceInr,
    this.description,
    this.bodyPart,
    this.discountedPriceInr,
    this.preparationInstructions,
    this.reportDeliveryTime,
    this.appointmentDurationMinutes,
    this.machineDetails,
  });

  final String id;
  final String scanName;
  final int priceInr;
  final String? description;
  final String? bodyPart;
  final int? discountedPriceInr;
  final String? preparationInstructions;
  final String? reportDeliveryTime;
  final int? appointmentDurationMinutes;
  final String? machineDetails;

  Map<String, dynamic> toJson() => {
        'id': id,
        'scanName': scanName,
        'priceInr': priceInr,
        if (description != null) 'description': description,
        if (bodyPart != null) 'bodyPart': bodyPart,
        if (discountedPriceInr != null) 'discountedPriceInr': discountedPriceInr,
        if (preparationInstructions != null)
          'preparationInstructions': preparationInstructions,
        if (reportDeliveryTime != null) 'reportDeliveryTime': reportDeliveryTime,
        if (appointmentDurationMinutes != null)
          'appointmentDurationMinutes': appointmentDurationMinutes,
        if (machineDetails != null) 'machineDetails': machineDetails,
        'enabled': true,
      };
}

class LabStaffMemberReg {
  const LabStaffMemberReg({
    required this.id,
    required this.role,
    required this.name,
    this.mobile,
    this.email,
    this.qualification,
    this.experienceYears,
    this.workingShift,
  });

  final String id;
  final String role;
  final String name;
  final String? mobile;
  final String? email;
  final String? qualification;
  final int? experienceYears;
  final String? workingShift;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'name': name,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        if (qualification != null) 'qualification': qualification,
        if (experienceYears != null) 'experienceYears': experienceYears,
        if (workingShift != null) 'workingShift': workingShift,
      };
}

class LabBankDetailsReg {
  const LabBankDetailsReg({
    this.accountHolderName,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.cancelledChequeUrl,
  });

  final String? accountHolderName;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? cancelledChequeUrl;

  Map<String, dynamic> toJson() => {
        if (accountHolderName != null) 'accountHolderName': accountHolderName,
        if (bankName != null) 'bankName': bankName,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (ifscCode != null) 'ifscCode': ifscCode,
        if (upiId != null) 'upiId': upiId,
        if (cancelledChequeUrl != null) 'cancelledChequeUrl': cancelledChequeUrl,
      };
}

/// Extended offered test fields for registration.
extension LabOfferedTestRegistration on LabOfferedTest {
  Map<String, dynamic> toRegistrationJson({
    String? subcategoryId,
    String? sampleType,
    bool fastingRequired = false,
    List<String> healthRisks = const [],
    List<String> healthConditions = const [],
    List<String> bodyOrgans = const [],
    List<String> includedParameters = const [],
    String? imageUrl,
  }) {
    return {
      ...toJson(),
      if (subcategoryId != null) 'subcategoryId': subcategoryId,
      if (sampleType != null) 'sampleType': sampleType,
      'fastingRequired': fastingRequired,
      if (healthRisks.isNotEmpty) 'healthRisks': healthRisks,
      if (healthConditions.isNotEmpty) 'healthConditions': healthConditions,
      if (bodyOrgans.isNotEmpty) 'bodyOrgans': bodyOrgans,
      if (includedParameters.isNotEmpty) 'includedParameters': includedParameters,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}