import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/india_geography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/address_autocomplete_field.dart';
import 'address_type_icon.dart';
import 'select_location_navigation.dart';
import 'selected_location.dart';

class LocationSelectorField extends StatelessWidget {
  const LocationSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Service location',
    this.hint = 'Search for area, street name...',
    this.requiredSelection = true,
    this.requireCityPincode = false,
  });

  final SelectedLocationResult? value;
  final ValueChanged<SelectedLocationResult> onChanged;
  final String label;
  final String hint;
  final bool requiredSelection;
  final bool requireCityPincode;

  @override
  Widget build(BuildContext context) {
    final selected = value != null && value!.addressLine.trim().isNotEmpty;
    return FormField<SelectedLocationResult>(
      validator: (_) {
        if (!requiredSelection) return null;
        if (value == null || value!.addressLine.trim().length < 5) {
          return 'Select a location';
        }
        if (requireCityPincode && !value!.hasBookingDetails) {
          return 'Add city and pincode for this location';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.white,
              borderRadius: AppDecorations.borderRadiusLg,
              child: InkWell(
                borderRadius: AppDecorations.borderRadiusLg,
                onTap: () async {
                  final result = await openSelectLocation(
                    context,
                    args: SelectLocationArgs(initial: value),
                  );
                  if (result != null) {
                    onChanged(result);
                    state.didChange(result);
                  }
                },
                child: selected
                    ? _SelectedAddressCard(value: value!)
                    : _EmptySearchCard(hint: hint),
              ),
            ),
            if (selected && requireCityPincode && !value!.hasBookingDetails) ...[
              const SizedBox(height: 10),
              Text(
                'Add city and pincode so the provider can reach you.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _CityPincodeRow(
                key: ValueKey(
                  '${value!.savedAddressId ?? ''}|${value!.addressLine}',
                ),
                value: value!,
                onChanged: (next) {
                  onChanged(next);
                  state.didChange(next);
                },
              ),
            ],
            if (state.hasError) ...[
              const SizedBox(height: 6),
              Text(
                state.errorText!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmptySearchCard extends StatelessWidget {
  const _EmptySearchCard({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
        ],
      ),
    );
  }
}

class _SelectedAddressCard extends StatelessWidget {
  const _SelectedAddressCard({required this.value});

  final SelectedLocationResult value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.primary, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressTypeIcon(label: value.displayLabel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.displayLabel,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.displayLine,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (value.phone != null && value.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Phone number: ${value.phone}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'Change',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityPincodeRow extends StatefulWidget {
  const _CityPincodeRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SelectedLocationResult value;
  final ValueChanged<SelectedLocationResult> onChanged;

  @override
  State<_CityPincodeRow> createState() => _CityPincodeRowState();
}

class _CityPincodeRowState extends State<_CityPincodeRow> {
  late final TextEditingController _city;
  late final TextEditingController _pincode;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.value.city ?? '');
    _pincode = TextEditingController(text: widget.value.pincode ?? '');
  }

  @override
  void didUpdateWidget(covariant _CityPincodeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.city != widget.value.city &&
        _city.text != (widget.value.city ?? '')) {
      _city.text = widget.value.city ?? '';
    }
    if (oldWidget.value.pincode != widget.value.pincode &&
        _pincode.text != (widget.value.pincode ?? '')) {
      _pincode.text = widget.value.pincode ?? '';
    }
  }

  @override
  void dispose() {
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.value.copyWith(
        city: _city.text.trim(),
        pincode: _pincode.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: AddressAutocompleteField(
            controller: _city,
            label: 'City',
            hint: 'e.g. Bengaluru',
            prefixIcon: Icons.location_city_outlined,
            options: IndiaGeography.districtsFor(state: widget.value.state),
            onChanged: (_) => _emit(),
            onSelected: (_) => _emit(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _pincode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              labelText: 'Pincode',
              prefixIcon: Icon(Icons.pin_drop_outlined),
            ),
          ),
        ),
      ],
    );
  }
}
