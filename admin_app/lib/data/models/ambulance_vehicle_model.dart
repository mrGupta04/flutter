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
  });

  factory AmbulanceVehicleModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceVehicleModel(
      id: json['id'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int?,
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
    );
  }

  String get displayLabel {
    final plate = registrationNumber.isNotEmpty ? registrationNumber : 'No plate';
    final type = vehicleType.isNotEmpty ? vehicleType : 'Vehicle';
    return '$type — $plate';
  }
}
