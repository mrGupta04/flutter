import 'package:flutter/material.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../core/utils/doctor_location_utils.dart';
import '../../../../features/online_consult/online_consult_navigation.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';

/// Vertical list tile for doctor search results (1mg-style card).
class DoctorSearchResultTile extends StatelessWidget {
  const DoctorSearchResultTile({
    super.key,
    required this.doctor,
    this.consultationFilter,
    this.showBottomDivider = true,
    this.distanceKm,
  });

  final DoctorModel doctor;
  final ConsultationType? consultationFilter;
  final bool showBottomDivider;
  final double? distanceKm;

  String? get _distanceLabel {
    final km = distanceKm;
    if (km == null) return null;
    if (km < 1) return 'Less than 1 km away';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return DoctorListingCard(
      doctor: doctor,
      showVerifiedIcon: true,
      showBottomDivider: showBottomDivider,
      consultationFilter: consultationFilter,
      footerNote: _distanceLabel,
      showActionButtons: doctor.offersOnlineConsult ||
          doctor.offersVisitSite ||
          doctor.offersBookHome ||
          doctorHasMapLocation(doctor),
      onTap: () => onDoctorCardTap(context, doctor),
      onOnlineConsultTap: () => openOnlineConsultBooking(context, doctor),
      onClinicTap: () => openHospitalVisitBooking(context, doctor),
      onHomeVisitTap: () => openHomeVisitBooking(context, doctor),
      onOpenMapTap: () => openDoctorInGoogleMaps(context, doctor),
    );
  }
}
