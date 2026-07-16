import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/text_controller_utils.dart';
import '../../core/utils/validation_utils.dart';
import '../../core/widgets/custom_widgets.dart';
import 'registration_map_picker.dart';

/// How the user provides their address during registration.
enum RegistrationLocationInputMode {
  /// Type address (city, state, pincode); optionally locate on map.
  manual,

  /// Pin on map / use GPS; address fields fill automatically.
  map,
}

/// Segmented control: Enter manually ↔ Use location.
class RegistrationLocationModeToggle extends StatelessWidget {
  const RegistrationLocationModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final RegistrationLocationInputMode mode;
  final ValueChanged<RegistrationLocationInputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How do you want to add your location?',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<RegistrationLocationInputMode>(
            segments: const [
              ButtonSegment(
                value: RegistrationLocationInputMode.manual,
                label: Text('Enter manually'),
                icon: Icon(Icons.edit_location_alt_outlined, size: 18),
              ),
              ButtonSegment(
                value: RegistrationLocationInputMode.map,
                label: Text('Use location'),
                icon: Icon(Icons.my_location_outlined, size: 18),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (next) {
              if (next.isNotEmpty) onChanged(next.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textSecondary;
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mode == RegistrationLocationInputMode.manual
              ? 'Type your address, then tap “Locate address” so patients can find you on the map.'
              : 'Use GPS or tap the map. We’ll fill address fields for you to confirm.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Standard address / city / state / pincode fields.
class RegistrationAddressFields extends StatelessWidget {
  const RegistrationAddressFields({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.pincodeController,
    this.addressLabel = 'Address',
    this.addressHint = 'Street, building, area',
    this.addressMaxLines = 1,
    this.compactCityState = false,
  });

  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;
  final String addressLabel;
  final String addressHint;
  final int addressMaxLines;
  final bool compactCityState;

  @override
  Widget build(BuildContext context) {
    final cityField = CustomTextField(
      controller: cityController,
      label: 'City',
      hint: 'e.g. Bengaluru',
      prefixIcon: Icons.location_city_outlined,
      validator: ValidationUtils.validateCity,
    );
    final stateField = CustomTextField(
      controller: stateController,
      label: 'State',
      hint: 'e.g. Karnataka',
      prefixIcon: Icons.map_outlined,
      validator: ValidationUtils.validateState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: addressController,
          label: addressLabel,
          hint: addressHint,
          prefixIcon: Icons.home_outlined,
          maxLines: addressMaxLines,
          validator: ValidationUtils.validateAddress,
        ),
        const SizedBox(height: 12),
        if (compactCityState)
          Row(
            children: [
              Expanded(child: cityField),
              const SizedBox(width: 8),
              Expanded(child: stateField),
            ],
          )
        else ...[
          cityField,
          const SizedBox(height: 12),
          stateField,
        ],
        const SizedBox(height: 12),
        CustomTextField(
          controller: pincodeController,
          label: 'Pincode',
          hint: '6-digit pincode',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.pin_drop_outlined,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: ValidationUtils.validatePincode,
        ),
      ],
    );
  }
}

/// Forward-geocodes typed address and updates map pin / controllers.
class RegistrationLocateAddressButton extends StatefulWidget {
  const RegistrationLocateAddressButton({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.pincodeController,
    required this.onLocated,
    this.fillMissingFields = true,
  });

  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;
  final void Function(double latitude, double longitude) onLocated;
  final bool fillMissingFields;

  @override
  State<RegistrationLocateAddressButton> createState() =>
      _RegistrationLocateAddressButtonState();
}

class _RegistrationLocateAddressButtonState
    extends State<RegistrationLocateAddressButton> {
  bool _loading = false;

  Future<void> _locate() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final place = await GeocodingService.forwardGeocode(
        address: widget.addressController.text,
        city: widget.cityController.text,
        state: widget.stateController.text,
        pincode: widget.pincodeController.text,
      );
      if (!mounted) return;

      if (widget.fillMissingFields) {
        final a = place.address;
        if (widget.addressController.text.trim().isEmpty) {
          setControllerText(widget.addressController, a.address);
        }
        if (widget.cityController.text.trim().isEmpty && a.city.isNotEmpty) {
          setControllerText(widget.cityController, a.city);
        }
        if (widget.stateController.text.trim().isEmpty && a.state.isNotEmpty) {
          setControllerText(widget.stateController, a.state);
        }
        if (widget.pincodeController.text.trim().isEmpty &&
            a.pincode.isNotEmpty) {
          setControllerText(widget.pincodeController, a.pincode);
        }
      }

      widget.onLocated(place.latitude, place.longitude);
      SnackBarHelper.showSuccess(
        context,
        'Address located on the map',
      );
    } on GeocodingFailure catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Could not locate that address. Try again or use the map.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _locate,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 48),
      ),
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Icon(Icons.search_rounded, color: AppColors.primary),
      label: Text(
        _loading ? 'Locating address…' : 'Locate address on map',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Full location block: mode toggle + manual fields / map picker.
///
/// Use [extraManualTop] for lab-style fields (building, street, etc.).
/// Use [footer] for content always shown after (radius, coverage, photos).
class RegistrationLocationBlock extends StatelessWidget {
  const RegistrationLocationBlock({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.pincodeController,
    required this.latitude,
    required this.longitude,
    required this.onLocationChanged,
    this.onAddressResolved,
    this.addressLabel = 'Address',
    this.addressHint = 'Street, building, area',
    this.addressMaxLines = 1,
    this.compactCityState = false,
    this.showStandardAddressFields = true,
    this.extraManualTop,
    this.mapEmptyHint =
        'Tap the map or use current location to pin your location.',
    this.mapWebTitle = 'Map location',
    this.footer,
  });

  final RegistrationLocationInputMode mode;
  final ValueChanged<RegistrationLocationInputMode> onModeChanged;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;
  final double? latitude;
  final double? longitude;
  final void Function(double latitude, double longitude) onLocationChanged;
  final void Function({
    required String address,
    required String city,
    required String state,
    required String pincode,
  })? onAddressResolved;
  final String addressLabel;
  final String addressHint;
  final int addressMaxLines;
  final bool compactCityState;
  final bool showStandardAddressFields;
  final Widget? extraManualTop;
  final String mapEmptyHint;
  final String mapWebTitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final pinned = latitude != null && longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegistrationLocationModeToggle(
          mode: mode,
          onChanged: onModeChanged,
        ),
        const SizedBox(height: 16),
        if (mode == RegistrationLocationInputMode.manual) ...[
          if (extraManualTop != null) ...[
            extraManualTop!,
            const SizedBox(height: 12),
          ],
          if (showStandardAddressFields)
            RegistrationAddressFields(
              addressController: addressController,
              cityController: cityController,
              stateController: stateController,
              pincodeController: pincodeController,
              addressLabel: addressLabel,
              addressHint: addressHint,
              addressMaxLines: addressMaxLines,
              compactCityState: compactCityState,
            ),
          const SizedBox(height: 12),
          RegistrationLocateAddressButton(
            addressController: addressController,
            cityController: cityController,
            stateController: stateController,
            pincodeController: pincodeController,
            onLocated: onLocationChanged,
          ),
          if (pinned) ...[
            const SizedBox(height: 8),
            Text(
              'Located: Lat ${latitude!.toStringAsFixed(5)}, '
              'Lng ${longitude!.toStringAsFixed(5)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ] else ...[
          RegistrationMapPicker(
            addressController: addressController,
            cityController: cityController,
            stateController: stateController,
            pincodeController: pincodeController,
            initialLatitude: latitude,
            initialLongitude: longitude,
            onLocationChanged: onLocationChanged,
            onAddressResolved: onAddressResolved,
            emptyHint: mapEmptyHint,
            webTitle: mapWebTitle,
          ),
          if (showStandardAddressFields) ...[
            const SizedBox(height: 16),
            Text(
              'Confirm address',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Edit if anything looks incomplete.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            RegistrationAddressFields(
              addressController: addressController,
              cityController: cityController,
              stateController: stateController,
              pincodeController: pincodeController,
              addressLabel: addressLabel,
              addressHint: addressHint,
              addressMaxLines: addressMaxLines,
              compactCityState: compactCityState,
            ),
          ],
          if (extraManualTop != null) ...[
            const SizedBox(height: 12),
            Text(
              'Building details (optional)',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            extraManualTop!,
          ],
        ],
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );
  }
}
