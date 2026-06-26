import 'package:flutter/material.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../core/utils/doctor_location_utils.dart';
import '../../../../features/online_consult/online_consult_navigation.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';

/// Vertical list tile for doctor search results (1mg-style card).
class DoctorSearchResultTile extends StatelessWidget {
  const DoctorSearchResultTile({
    super.key,
    required this.doctor,
    this.showBottomDivider = true,
  });

  final DoctorModel doctor;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    return DoctorListingCard(
      doctor: doctor,
      showVerifiedIcon: true,
      showBottomDivider: showBottomDivider,
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
