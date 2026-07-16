import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';

/// Small map preview for a patient's home-visit location.
/// Includes Google Maps navigation so the doctor can follow directions in real time.
class PatientLocationMapCard extends StatefulWidget {
  const PatientLocationMapCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.addressLine,
    this.title = 'Patient location',
    this.mapHeight = 190,
  });

  final double latitude;
  final double longitude;
  final String? addressLine;
  final String title;
  final double mapHeight;

  @override
  State<PatientLocationMapCard> createState() => _PatientLocationMapCardState();
}

class _PatientLocationMapCardState extends State<PatientLocationMapCard> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}&travelmode=driving',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _openInGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pin = LatLng(widget.latitude, widget.longitude);

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
            widget.title,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.addressLine != null && widget.addressLine!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.addressLine!.trim(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: widget.mapHeight,
              child: kIsWeb
                  ? _MapPlaceholder(
                      title: widget.title,
                      address: widget.addressLine,
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
                          markerId: const MarkerId('patient_pin'),
                          position: pin,
                          infoWindow: InfoWindow(
                            title: widget.title,
                            snippet: widget.addressLine,
                          ),
                        ),
                      },
                      onMapCreated: (c) => _controller = c,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Navigate (Google Maps)',
            icon: Icons.directions_rounded,
            onPressed: _openDirections,
            height: 48,
          ),
          const SizedBox(height: 8),
          CustomOutlineButton(
            label: 'Open in Google Maps',
            icon: Icons.map_outlined,
            onPressed: _openInGoogleMaps,
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
  });

  final String title;
  final String? address;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.labelLarge,
            textAlign: TextAlign.center,
          ),
          if (address != null && address!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              address!.trim(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

