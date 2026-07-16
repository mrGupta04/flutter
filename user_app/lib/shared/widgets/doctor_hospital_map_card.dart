import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/doctor_location_utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/models/doctor_model.dart';

/// In-app hospital/clinic map preview with live user location and Google Maps navigation.
class DoctorHospitalMapCard extends StatefulWidget {
  const DoctorHospitalMapCard({
    super.key,
    required this.doctor,
    this.clinicName,
    this.clinicAddress,
    this.mapHeight = 220,
  });

  final DoctorModel doctor;
  final String? clinicName;
  final String? clinicAddress;
  final double mapHeight;

  @override
  State<DoctorHospitalMapCard> createState() => _DoctorHospitalMapCardState();
}

class _DoctorHospitalMapCardState extends State<DoctorHospitalMapCard> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  String get _title {
    final name = widget.clinicName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return widget.doctor.clinicName?.trim().isNotEmpty == true
        ? widget.doctor.clinicName!.trim()
        : 'Hospital / Clinic';
  }

  String get _address {
    final fromSlots = widget.clinicAddress?.trim();
    if (fromSlots != null && fromSlots.isNotEmpty) return fromSlots;
    return formatDoctorClinicAddress(widget.doctor);
  }

  LatLng? get _hospitalLatLng {
    final lat = widget.doctor.latitude;
    final lng = widget.doctor.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    if (!doctorHasMapLocation(widget.doctor)) {
      return const SizedBox.shrink();
    }

    final pin = _hospitalLatLng;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hospital on map',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your live location is shown as the blue dot. Tap Navigate to follow turn-by-turn directions in Google Maps.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: widget.mapHeight,
              child: pin == null || kIsWeb
                  ? _MapPlaceholder(
                      title: _title,
                      address: _address,
                      isWeb: kIsWeb,
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: pin,
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                      mapToolbarEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('doctor_hospital'),
                          position: pin,
                          infoWindow: InfoWindow(
                            title: _title,
                            snippet: _address.isNotEmpty ? _address : null,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                      },
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
            ),
          ),
          if (_address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          CustomButton(
            label: 'Navigate with Google Maps',
            icon: Icons.directions_rounded,
            onPressed: () =>
                openDoctorDirectionsInGoogleMaps(context, widget.doctor),
            height: 48,
          ),
          const SizedBox(height: 8),
          CustomOutlineButton(
            label: 'Open in Google Maps',
            icon: Icons.map_outlined,
            onPressed: () => openDoctorInGoogleMaps(context, widget.doctor),
            height: 44,
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.title,
    required this.address,
    required this.isWeb,
  });

  final String title;
  final String address;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_hospital_rounded,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.labelLarge),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              address,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            isWeb
                ? 'Use Navigate below to open Google Maps with live directions.'
                : 'Hospital pin will appear when coordinates are available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
