import 'package:flutter/material.dart';
import '../../../../data/models/doctor_model.dart';
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
      showActionButtons: false,
    );
  }
}
