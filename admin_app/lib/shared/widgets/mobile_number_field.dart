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
  late final FocusNode _focusNode;
  DateTime? _suppressSelectionUntil;
  VoidCallback? _controllerListener;

  @override
  void initState() {
    super.initState();
    _selectedCountry = PhoneCountries.findByDialCode(widget.countryCode);
    _focusNode = FocusNode(debugLabel: 'MobileNumberField');
    _focusNode.addListener(_handleFocusChange);
    _attachController(widget.mobileController);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _detachController(widget.mobileController);
    _focusNode.dispose();
    super.dispose();
  }

  void _attachController(TextEditingController controller) {
    void listener() => _collapseAccidentalSelection();
    _controllerListener = listener;
    controller.addListener(listener);
  }

  void _detachController(TextEditingController controller) {
    final listener = _controllerListener;
    if (listener != null) {
      controller.removeListener(listener);
      _controllerListener = null;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _suppressSelectionUntil = null;
      return;
    }
    _suppressSelectionUntil =
        DateTime.now().add(const Duration(milliseconds: 400));
    _collapseAccidentalSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _collapseAccidentalSelection();
    });
  }

  void _collapseAccidentalSelection() {
    final until = _suppressSelectionUntil;
    if (until == null || DateTime.now().isAfter(until)) return;
    if (!_focusNode.hasFocus) return;

    final controller = widget.mobileController;
    final text = controller.text;
    if (text.isEmpty) return;

    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final caret = selection.extentOffset.clamp(0, text.length);
    controller.selection = TextSelection.collapsed(offset: caret);
  }

  @override
  void didUpdateWidget(covariant MobileNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode != widget.countryCode) {
      _selectedCountry = PhoneCountries.findByDialCode(widget.countryCode);
    }
    if (oldWidget.mobileController != widget.mobileController) {
      _detachController(oldWidget.mobileController);
      _attachController(widget.mobileController);
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
      focusNode: _focusNode,
      validator: _validate,
      keyboardType: TextInputType.phone,
      inputFormatters: ValidationUtils.mobileInputFormatters(
        countryCode: _selectedCountry.dialCode,
      ),
      onTap: _collapseAccidentalSelection,
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
