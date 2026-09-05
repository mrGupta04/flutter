class AmbulanceFareModel {
  const AmbulanceFareModel({
    this.baseFare = 0,
    this.distanceCharge = 0,
    this.timeCharge = 0,
    this.typeCharge = 0,
    this.equipmentCharge = 0,
    this.emergencySurcharge = 0,
    this.nightCharge = 0,
    this.waitingCharge = 0,
    this.total = 0,
    this.estimated = true,
    this.currency = 'INR',
    this.distanceKm,
    this.durationMinutes,
  });

  final double baseFare;
  final double distanceCharge;
  final double timeCharge;
  final double typeCharge;
  final double equipmentCharge;
  final double emergencySurcharge;
  final double nightCharge;
  final double waitingCharge;
  final double total;
  final bool estimated;
  final String currency;
  final double? distanceKm;
  final double? durationMinutes;

  factory AmbulanceFareModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AmbulanceFareModel();
    double n(dynamic value) => (value is num) ? value.toDouble() : 0;
    return AmbulanceFareModel(
      baseFare: n(json['baseFare']),
      distanceCharge: n(json['distanceCharge']),
      timeCharge: n(json['timeCharge']),
      typeCharge: n(json['typeCharge']),
      equipmentCharge: n(json['equipmentCharge']),
      emergencySurcharge: n(json['emergencySurcharge']),
      nightCharge: n(json['nightCharge']),
      waitingCharge: n(json['waitingCharge']),
      total: n(json['total']),
      estimated: json['estimated'] != false,
      currency: json['currency'] as String? ?? 'INR',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toDouble(),
    );
  }
}

class AmbulanceBookingModel {
  const AmbulanceBookingModel({
    required this.id,
    this.ambulanceId,
    this.ambulanceServiceName,
    this.patientName,
    this.patientMobile,
    this.patientAge,
    this.patientGender,
    this.patientCondition,
    this.consciousState,
    this.emergencyCategory,
    this.contactPerson,
    this.contactPhone,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropAddress,
    this.dropLatitude,
    this.dropLongitude,
    this.destinationType,
    this.destinationHospitalName,
    this.vehicleTypeRequested,
    this.bookingKind = 'emergency',
    this.scheduledAt,
    this.isEmergency = true,
    this.status = 'requested',
    this.statusLabel,
    this.estimatedArrivalMinutes,
    this.assignedDriverName,
    this.assignedVehicleRegistration,
    this.assignedVehicleType,
    this.liveLatitude,
    this.liveLongitude,
    this.liveLocationUpdatedAt,
    this.locationMessage,
    this.locationUnavailable = false,
    this.fare,
    this.paymentStatus,
    this.paymentMethod,
    this.timeline = const [],
    this.createdAt,
  });

  final String id;
  final String? ambulanceId;
  final String? ambulanceServiceName;
  final String? patientName;
  final String? patientMobile;
  final int? patientAge;
  final String? patientGender;
  final String? patientCondition;
  final String? consciousState;
  final String? emergencyCategory;
  final String? contactPerson;
  final String? contactPhone;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? dropAddress;
  final double? dropLatitude;
  final double? dropLongitude;
  final String? destinationType;
  final String? destinationHospitalName;
  final String? vehicleTypeRequested;
  final String bookingKind;
  final DateTime? scheduledAt;
  final bool isEmergency;
  final String status;
  final String? statusLabel;
  final int? estimatedArrivalMinutes;
  final String? assignedDriverName;
  final String? assignedVehicleRegistration;
  final String? assignedVehicleType;
  final double? liveLatitude;
  final double? liveLongitude;
  final DateTime? liveLocationUpdatedAt;
  final String? locationMessage;
  final bool locationUnavailable;
  final AmbulanceFareModel? fare;
  final String? paymentStatus;
  final String? paymentMethod;
  final List<Map<String, dynamic>> timeline;
  final DateTime? createdAt;

  bool get isActive => const {
        'requested',
        'searching_ambulance',
        'ambulance_assigned',
        'driver_accepted',
        'accepted',
        'dispatched',
        'driver_en_route',
        'en_route',
        'arrived_at_pickup',
        'arrived',
        'patient_picked_up',
        'en_route_to_destination',
        'arrived_at_destination',
      }.contains(status);

  bool get isSearching => status == 'searching_ambulance' || status == 'requested';

  bool get canTrack => isActive && !isSearching;

  bool get canReview => status == 'trip_completed' || status == 'completed';

  bool get needsEscalation =>
      status == 'no_answer' || status == 'expired' || status == 'failed';

  factory AmbulanceBookingModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    return AmbulanceBookingModel(
      id: json['id']?.toString() ?? '',
      ambulanceId: json['ambulanceId']?.toString(),
      ambulanceServiceName: json['ambulanceServiceName'] as String?,
      patientName: json['patientName'] as String?,
      patientMobile: json['patientMobile'] as String?,
      patientAge: (json['patientAge'] as num?)?.toInt(),
      patientGender: json['patientGender'] as String?,
      patientCondition: json['patientCondition'] as String?,
      consciousState: json['consciousState'] as String?,
      emergencyCategory: json['emergencyCategory'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactPhone: json['contactPhone'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      dropAddress: json['dropAddress'] as String?,
      dropLatitude: (json['dropLatitude'] as num?)?.toDouble(),
      dropLongitude: (json['dropLongitude'] as num?)?.toDouble(),
      destinationType: json['destinationType'] as String?,
      destinationHospitalName: json['destinationHospitalName'] as String?,
      vehicleTypeRequested: json['vehicleTypeRequested'] as String?,
      bookingKind: json['bookingKind'] as String? ?? 'emergency',
      scheduledAt: parseDate(json['scheduledAt']),
      isEmergency: json['isEmergency'] != false,
      status: json['status'] as String? ?? 'requested',
      statusLabel: json['statusLabel'] as String?,
      estimatedArrivalMinutes: (json['estimatedArrivalMinutes'] as num?)?.toInt(),
      assignedDriverName: json['assignedDriverName'] as String?,
      assignedVehicleRegistration: json['assignedVehicleRegistration'] as String?,
      assignedVehicleType: json['assignedVehicleType'] as String?,
      liveLatitude: (json['liveLatitude'] as num?)?.toDouble(),
      liveLongitude: (json['liveLongitude'] as num?)?.toDouble(),
      liveLocationUpdatedAt: parseDate(json['liveLocationUpdatedAt']),
      locationMessage: (json['location'] is Map)
          ? (json['location'] as Map)['message']?.toString()
          : null,
      locationUnavailable: json['locationUnavailable'] == true,
      fare: json['fare'] is Map<String, dynamic>
          ? AmbulanceFareModel.fromJson(json['fare'] as Map<String, dynamic>)
          : null,
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      timeline: json['timeline'] is List
          ? (json['timeline'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      createdAt: parseDate(json['createdAt']),
    );
  }
}
