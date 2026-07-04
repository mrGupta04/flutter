import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/phone_countries.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validation_utils.dart';

/// Mobile number field with country code selector (India +91 default).
class MobileNumberField extends StatefulWidget {
  final TextEditingController mobileController;
  final String countryCode;
  final ValueChanged<String>? onCountryCodeChanged;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;

  const MobileNumberField({
    super.key,
    required this.mobileController,
    this.countryCode = PhoneCountries.defaultDialCode,
    this.onCountryCodeChanged,
    this.label = 'Mobile number',
    this.hint = '10-digit mobile number',
    this.validator,
  });

  @override
  State<MobileNumberField> createState() => _MobileNumberFieldState();
}

class _MobileNumberFieldState extends State<MobileNumberField> {
  late PhoneCountry _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = PhoneCountries.findByDialCode(widget.countryCode);
  }

  @override
  void didUpdateWidget(covariant MobileNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode != widget.countryCode) {
      _selectedCountry = PhoneCountries.findByDialCode(widget.countryCode);
    }
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<PhoneCountry>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Select country code',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              ...PhoneCountries.supported.map(
                (country) => ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(country.name),
                  trailing: Text('+${country.dialCode}'),
                  selected: country.dialCode == _selectedCountry.dialCode,
                  onTap: () => Navigator.pop(context, country),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked == null || picked.dialCode == _selectedCountry.dialCode) {
      return;
    }

    setState(() => _selectedCountry = picked);
    widget.onCountryCodeChanged?.call(picked.dialCode);
  }

  String? _validate(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }
    return ValidationUtils.validatePhoneNumber(
      value,
      countryCode: _selectedCountry.dialCode,
    );
  }

  Widget _buildCountryCodePicker() {
    return InkWell(
      onTap: _pickCountry,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Code',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountry.flag,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 6),
            Text(
              '+${_selectedCountry.dialCode}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, color: AppColors.grey500, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: widget.mobileController,
      validator: _validate,
      keyboardType: TextInputType.phone,
      inputFormatters: ValidationUtils.mobileInputFormatters(
        countryCode: _selectedCountry.dialCode,
      ),
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(
          Icons.phone_outlined,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 360;

        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCountryCodePicker(),
              const SizedBox(height: 12),
              _buildPhoneField(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: _buildCountryCodePicker(),
            ),
            const SizedBox(width: 10),
            Expanded(child: _buildPhoneField()),
          ],
        );
      },
    );
  }
}
