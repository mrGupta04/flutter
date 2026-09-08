class AmbulanceVehicleModel {
  final String id;
  final String registrationNumber;
  final String vehicleType;
  final String make;
  final String model;
  final int? year;
  final String color;
  final int? capacity;
  final bool hasOxygen;
  final bool hasVentilator;
  final bool hasDefibrillator;
  final bool hasStretcher;
  final bool hasAed;
  final String? rcBookUrl;
  final String? insuranceUrl;
  final String? fitnessCertificateUrl;
  final String? pollutionCertificateUrl;
  final String? photoFrontUrl;
  final String? photoBackUrl;
  final String? photoInteriorUrl;
  final String status;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationAt;
  final String? assignedDriverId;
  final String? currentBookingId;
  final double? baseFare;
  final double? perKm;
  final double? minFare;

  AmbulanceVehicleModel({
    required this.id,
    this.registrationNumber = '',
    this.vehicleType = '',
    this.make = '',
    this.model = '',
    this.year,
    this.color = '',
    this.capacity,
    this.hasOxygen = false,
    this.hasVentilator = false,
    this.hasDefibrillator = false,
    this.hasStretcher = false,
    this.hasAed = false,
    this.rcBookUrl,
    this.insuranceUrl,
    this.fitnessCertificateUrl,
    this.pollutionCertificateUrl,
    this.photoFrontUrl,
    this.photoBackUrl,
    this.photoInteriorUrl,
    this.status = 'OFFLINE',
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationAt,
    this.assignedDriverId,
    this.currentBookingId,
    this.baseFare,
    this.perKm,
    this.minFare,
  });

  factory AmbulanceVehicleModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceVehicleModel(
      id: json['id'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: (json['year'] as num?)?.toInt(),
      color: json['color'] as String? ?? '',
      capacity: json['capacity'] as int?,
      hasOxygen: json['hasOxygen'] as bool? ?? false,
      hasVentilator: json['hasVentilator'] as bool? ?? false,
      hasDefibrillator: json['hasDefibrillator'] as bool? ?? false,
      hasStretcher: json['hasStretcher'] as bool? ?? false,
      hasAed: json['hasAed'] as bool? ?? false,
      rcBookUrl: json['rcBookUrl'] as String?,
      insuranceUrl: json['insuranceUrl'] as String?,
      fitnessCertificateUrl: json['fitnessCertificateUrl'] as String?,
      pollutionCertificateUrl: json['pollutionCertificateUrl'] as String?,
      photoFrontUrl: json['photoFrontUrl'] as String?,
      photoBackUrl: json['photoBackUrl'] as String?,
      photoInteriorUrl: json['photoInteriorUrl'] as String?,
      status: json['status'] as String? ?? 'OFFLINE',
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      lastLocationAt: json['lastLocationAt'] != null
          ? DateTime.tryParse(json['lastLocationAt'].toString())
          : null,
      assignedDriverId: json['assignedDriverId'] as String?,
      currentBookingId: json['currentBookingId'] as String?,
      baseFare: (json['baseFare'] as num?)?.toDouble(),
      perKm: (json['perKm'] as num?)?.toDouble(),
      minFare: (json['minFare'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'registrationNumber': registrationNumber,
        'vehicleType': vehicleType,
        'make': make,
        'model': model,
        if (year != null) 'year': year,
        'color': color,
        if (capacity != null) 'capacity': capacity,
        'hasOxygen': hasOxygen,
        'hasVentilator': hasVentilator,
        'hasDefibrillator': hasDefibrillator,
        'hasStretcher': hasStretcher,
        'hasAed': hasAed,
        if (rcBookUrl != null) 'rcBookUrl': rcBookUrl,
        if (insuranceUrl != null) 'insuranceUrl': insuranceUrl,
        if (fitnessCertificateUrl != null)
          'fitnessCertificateUrl': fitnessCertificateUrl,
        if (pollutionCertificateUrl != null)
          'pollutionCertificateUrl': pollutionCertificateUrl,
        if (photoFrontUrl != null) 'photoFrontUrl': photoFrontUrl,
        if (photoBackUrl != null) 'photoBackUrl': photoBackUrl,
        if (photoInteriorUrl != null) 'photoInteriorUrl': photoInteriorUrl,
        'status': status,
        if (currentLatitude != null) 'currentLatitude': currentLatitude,
        if (currentLongitude != null) 'currentLongitude': currentLongitude,
        if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
        if (currentBookingId != null) 'currentBookingId': currentBookingId,
        if (baseFare != null) 'baseFare': baseFare,
        if (perKm != null) 'perKm': perKm,
        if (minFare != null) 'minFare': minFare,
      };

  AmbulanceVehicleModel copyWith({
    String? id,
    String? registrationNumber,
    String? vehicleType,
    String? make,
    String? model,
    int? year,
    String? color,
    int? capacity,
    bool? hasOxygen,
    bool? hasVentilator,
    bool? hasDefibrillator,
    bool? hasStretcher,
    bool? hasAed,
    String? rcBookUrl,
    String? insuranceUrl,
    String? fitnessCertificateUrl,
    String? pollutionCertificateUrl,
    String? photoFrontUrl,
    String? photoBackUrl,
    String? photoInteriorUrl,
    String? status,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationAt,
    String? assignedDriverId,
    String? currentBookingId,
    double? baseFare,
    double? perKm,
    double? minFare,
  }) {
    return AmbulanceVehicleModel(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      capacity: capacity ?? this.capacity,
      hasOxygen: hasOxygen ?? this.hasOxygen,
      hasVentilator: hasVentilator ?? this.hasVentilator,
      hasDefibrillator: hasDefibrillator ?? this.hasDefibrillator,
      hasStretcher: hasStretcher ?? this.hasStretcher,
      hasAed: hasAed ?? this.hasAed,
      rcBookUrl: rcBookUrl ?? this.rcBookUrl,
      insuranceUrl: insuranceUrl ?? this.insuranceUrl,
      fitnessCertificateUrl:
          fitnessCertificateUrl ?? this.fitnessCertificateUrl,
      pollutionCertificateUrl:
          pollutionCertificateUrl ?? this.pollutionCertificateUrl,
      photoFrontUrl: photoFrontUrl ?? this.photoFrontUrl,
      photoBackUrl: photoBackUrl ?? this.photoBackUrl,
      photoInteriorUrl: photoInteriorUrl ?? this.photoInteriorUrl,
      status: status ?? this.status,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationAt: lastLocationAt ?? this.lastLocationAt,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      baseFare: baseFare ?? this.baseFare,
      perKm: perKm ?? this.perKm,
      minFare: minFare ?? this.minFare,
    );
  }

  String get displayLabel {
    final plate = registrationNumber.isNotEmpty ? registrationNumber : 'No plate';
    final type = vehicleType.isNotEmpty ? vehicleType : 'Vehicle';
    return '$type — $plate';
  }
}
