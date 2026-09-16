import 'package:flutter/material.dart';

enum AmbulanceRideCategory {
  all('All'),
  priority('Priority Services'),
  lifeSupport('Life Support'),
  extraSpace('Extra Space'),
  specialized('Specialized');

  const AmbulanceRideCategory(this.label);
  final String label;
}

class AmbulanceVehicleType {
  const AmbulanceVehicleType({
    required this.id,
    required this.label,
    required this.category,
    required this.detail,
    this.shortLabel,
  });

  final String id;
  final String label;
  final AmbulanceRideCategory category;
  final String detail;
  final String? shortLabel;

  String get chipLabel => shortLabel ?? label;

  IconData get icon {
    switch (id) {
      case 'bls':
        return Icons.medical_services_outlined;
      case 'als':
        return Icons.emergency_outlined;
      case 'icu':
        return Icons.local_hospital_outlined;
      case 'cardiac':
        return Icons.favorite_outline;
      case 'trauma':
        return Icons.personal_injury_outlined;
      case 'neonatal':
      case 'pediatric':
        return Icons.child_care_outlined;
      case 'isolation':
        return Icons.masks_outlined;
      case 'bariatric':
        return Icons.airline_seat_flat_outlined;
      case 'patient_transport':
        return Icons.airport_shuttle_outlined;
      case 'first_responder':
        return Icons.two_wheeler_outlined;
      case 'air':
        return Icons.flight_outlined;
      case 'mortuary':
        return Icons.directions_car_outlined;
      case 'event':
        return Icons.event_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }
}

const ambulanceVehicleTypes = [
  AmbulanceVehicleType(
    id: 'als',
    label: 'Advanced Life Support',
    shortLabel: 'ALS',
    category: AmbulanceRideCategory.priority,
    detail: 'Doctor, ventilator & cardiac monitor',
  ),
  AmbulanceVehicleType(
    id: 'cardiac',
    label: 'Cardiac Ambulance',
    shortLabel: 'Cardiac',
    category: AmbulanceRideCategory.priority,
    detail: 'Heart emergency with defibrillator',
  ),
  AmbulanceVehicleType(
    id: 'trauma',
    label: 'Trauma Ambulance',
    shortLabel: 'Trauma',
    category: AmbulanceRideCategory.priority,
    detail: 'Accident & injury response',
  ),
  AmbulanceVehicleType(
    id: 'first_responder',
    label: 'First Responder / Bike Ambulance',
    shortLabel: 'Bike',
    category: AmbulanceRideCategory.priority,
    detail: 'Fastest first aid on two wheels',
  ),
  AmbulanceVehicleType(
    id: 'bls',
    label: 'Basic Life Support',
    shortLabel: 'BLS',
    category: AmbulanceRideCategory.lifeSupport,
    detail: 'EMT, oxygen & stretcher',
  ),
  AmbulanceVehicleType(
    id: 'icu',
    label: 'ICU Ambulance',
    shortLabel: 'ICU',
    category: AmbulanceRideCategory.lifeSupport,
    detail: 'Mobile ICU with critical-care kit',
  ),
  AmbulanceVehicleType(
    id: 'neonatal',
    label: 'Neonatal Ambulance',
    shortLabel: 'Neonatal',
    category: AmbulanceRideCategory.lifeSupport,
    detail: 'Incubator for newborns',
  ),
  AmbulanceVehicleType(
    id: 'pediatric',
    label: 'Pediatric Ambulance',
    shortLabel: 'Pediatric',
    category: AmbulanceRideCategory.lifeSupport,
    detail: 'Child-ready emergency care',
  ),
  AmbulanceVehicleType(
    id: 'isolation',
    label: 'Isolation Ambulance',
    shortLabel: 'Isolation',
    category: AmbulanceRideCategory.lifeSupport,
    detail: 'Infectious-case isolation cabin',
  ),
  AmbulanceVehicleType(
    id: 'basic',
    label: 'Basic Ambulance',
    shortLabel: 'Basic',
    category: AmbulanceRideCategory.extraSpace,
    detail: 'Standard patient transfer',
  ),
  AmbulanceVehicleType(
    id: 'patient_transport',
    label: 'Patient Transport Vehicle',
    shortLabel: 'Transport',
    category: AmbulanceRideCategory.extraSpace,
    detail: 'Non-emergency hospital transfer',
  ),
  AmbulanceVehicleType(
    id: 'bariatric',
    label: 'Bariatric Ambulance',
    shortLabel: 'Bariatric',
    category: AmbulanceRideCategory.extraSpace,
    detail: 'Extra space & lifting support',
  ),
  AmbulanceVehicleType(
    id: 'air',
    label: 'Air Ambulance',
    shortLabel: 'Air',
    category: AmbulanceRideCategory.specialized,
    detail: 'Helicopter / air medical transfer',
  ),
  AmbulanceVehicleType(
    id: 'mortuary',
    label: 'Mortuary Van',
    shortLabel: 'Mortuary',
    category: AmbulanceRideCategory.specialized,
    detail: 'Respectful last-mile transfer',
  ),
  AmbulanceVehicleType(
    id: 'event',
    label: 'Event Medical Ambulance',
    shortLabel: 'Event',
    category: AmbulanceRideCategory.specialized,
    detail: 'Standby cover for events',
  ),
];

const ambulanceVehicleTypeFilters = [
  'Basic Ambulance',
  'Basic Life Support',
  'Advanced Life Support',
  'ICU Ambulance',
  'Cardiac Ambulance',
  'Trauma Ambulance',
  'Neonatal Ambulance',
  'Pediatric Ambulance',
  'Isolation Ambulance',
  'Bariatric Ambulance',
  'Patient Transport',
  'First Responder / Bike Ambulance',
  'Air Ambulance',
  'Mortuary Van',
  'Event Medical Ambulance',
];
