import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';

/// Map + GPS picker that auto-fills address fields from reverse geocoding.
class RegistrationMapPicker extends StatefulWidget {
  const RegistrationMapPicker({
    super.key,
    this.addressController,
    this.cityController,
    this.stateController,
    this.pincodeController,
    this.initialLatitude,
    this.initialLongitude,
    this.onLocationChanged,
    this.onAddressResolved,
    this.emptyHint =
        'Tap the map or use current location to pin your location.',
    this.webTitle = 'Map location',
  });

  final TextEditingController? addressController;
  final TextEditingController? cityController;
  final TextEditingController? stateController;
  final TextEditingController? pincodeController;
  final double? initialLatitude;
  final double? initialLongitude;
  final void Function(double latitude, double longitude)? onLocationChanged;
  final void Function({
    required String address,
    required String city,
    required String state,
    required String pincode,
  })? onAddressResolved;
  final String emptyHint;
  final String webTitle;

  @override
  State<RegistrationMapPicker> createState() => _RegistrationMapPickerState();
}

class _RegistrationMapPickerState extends State<RegistrationMapPicker> {
  LatLng? _selected;
  bool _locating = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void didUpdateWidget(RegistrationMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLatitude != null &&
        widget.initialLongitude != null &&
        (_selected == null ||
            _selected!.latitude != widget.initialLatitude ||
            _selected!.longitude != widget.initialLongitude)) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _setMapPin(LatLng latLng) {
    setState(() => _selected = latLng);
    widget.onLocationChanged?.call(latLng.latitude, latLng.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  void _fillAddressFields(ResolvedAddress resolved) {
    widget.addressController?.text = resolved.address;
    widget.cityController?.text = resolved.city;
    widget.stateController?.text = resolved.state;
    widget.pincodeController?.text = resolved.pincode;
    widget.onAddressResolved?.call(
      address: resolved.address,
      city: resolved.city,
      state: resolved.state,
      pincode: resolved.pincode,
    );
  }

  Future<bool> _applyLocationWithAddress(LatLng latLng) async {
    _setMapPin(latLng);
    if (widget.addressController == null) return false;

    try {
      final resolved = await GeocodingService.reverseGeocode(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
      if (!mounted) return false;
      _fillAddressFields(resolved);
      return true;
    } on GeocodingFailure catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          '${e.message} Coordinates were saved — please type the address.',
        );
      }
      return false;
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      final addressFilled = await _applyLocationWithAddress(latLng);
      if (mounted && addressFilled) {
        SnackBarHelper.showSuccess(
          context,
          'Location and address filled from GPS',
        );
      } else if (mounted && widget.addressController == null) {
        SnackBarHelper.showSuccess(context, 'Current location set on map');
      }
    } on LocationFailure catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Could not get current location. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapTap(LatLng latLng) {
    if (_locating) return;
    setState(() => _locating = true);
    _applyLocationWithAddress(latLng).whenComplete(() {
      if (mounted) setState(() => _locating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = _selected ??
        const LatLng(AppConstants.defaultMapLat, AppConstants.defaultMapLng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: kIsWeb
                ? _WebMapFallback(
                    selected: _selected,
                    webTitle: widget.webTitle,
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initial,
                      zoom: AppConstants.defaultMapZoom,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _selected == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: _selected!,
                            ),
                          },
                    onTap: _onMapTap,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primary),
                ),
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.my_location, color: AppColors.primary),
                label: Text(
                  _locating
                      ? 'Getting location & address…'
                      : 'Use current location',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selected != null) ...[
          const SizedBox(height: 8),
          Text(
            'Pinned: Lat ${_selected!.latitude.toStringAsFixed(5)}, '
            'Lng ${_selected!.longitude.toStringAsFixed(5)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              kIsWeb
                  ? 'Allow location in the browser when prompted, or tap the map area on mobile.'
                  : widget.emptyHint,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback({
    required this.selected,
    required this.webTitle,
  });

  final LatLng? selected;
  final String webTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected == null ? Icons.map_outlined : Icons.location_on,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(webTitle, style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Text(
            selected == null
                ? 'Tap “Use current location” below — address fields will auto-fill.'
                : 'Location pinned. Address fields updated above.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
