import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/scan_center_model.dart';
import '../../../../data/repositories/scan_repository.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../data/models/scan_procedure_model.dart';

Future<void> showScanBookingSheet(
  BuildContext context, {
  required ScanCenterModel center,
  required ScanProcedure procedure,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ScanBookingSheet(
      center: center,
      procedure: procedure,
    ),
  );
}

class _ScanBookingSheet extends ConsumerStatefulWidget {
  const _ScanBookingSheet({
    required this.center,
    required this.procedure,
  });

  final ScanCenterModel center;
  final ScanProcedure procedure;

  @override
  ConsumerState<_ScanBookingSheet> createState() => _ScanBookingSheetState();
}

class _ScanBookingSheetState extends ConsumerState<_ScanBookingSheet> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _payAtCenter = false;
  bool _isSubmitting = false;
  String? _prescriptionName;
  bool _contrastRequired = false;

  static const _timeSlots = [
    '8:00 AM',
    '10:00 AM',
    '12:00 PM',
    '2:00 PM',
    '4:00 PM',
    '6:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTimeSlot = _timeSlots.first;
  }

  int get _basePrice => widget.procedure.effectivePrice;

  int get _discountAmount {
    final offer = widget.center.activeOffer;
    if (offer == null || !offer.isActiveNow) return 0;
    if (offer.discountType == 'percentage' && offer.discountValue != null) {
      return (_basePrice * offer.discountValue! / 100).round();
    }
    if (offer.discountType == 'flat' && offer.discountValue != null) {
      return offer.discountValue!.round();
    }
    return 0;
  }

  int get _total => (_basePrice - _discountAmount).clamp(0, _basePrice);

  Future<void> _callCenter() async {
    final phone = widget.center.mobileNumber?.trim();
    if (phone == null || phone.isEmpty) {
      custom.SnackBarHelper.showError(context, 'Phone number not available');
      return;
    }
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    if (!await launchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _prescriptionName = result.files.first.name);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null) return;
    if (widget.procedure.prescriptionRequired && _prescriptionName == null) {
      custom.SnackBarHelper.showError(
        context,
        'Doctor prescription is required for this scan.',
      );
      return;
    }

    final loggedIn = await ensureUserLoggedIn(
      context,
      message: 'Please log in to request a scan booking.',
    );
    if (!loggedIn || !mounted) return;

    final user = ref.read(patientAuthProvider).user;
    if (user == null) return;

    final centerId = widget.center.id;
    if (centerId == null || centerId.isEmpty) {
      custom.SnackBarHelper.showError(context, 'Invalid scan center');
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await ScanRepository().createBooking(
      scanCenterId: centerId,
      patientName: user.fullName,
      patientMobile: user.mobileNumber,
      patientEmail: user.email,
      patientId: user.id,
      countryCode: user.countryCode.isEmpty
          ? PhoneCountries.defaultDialCode
          : user.countryCode,
      scanId: widget.procedure.id,
      scanName: widget.procedure.name,
      categoryId: widget.procedure.category.id,
      scheduledDate: _selectedDate!,
      timeSlot: _selectedTimeSlot!,
      totalAmount: _total,
      contrastRequired: _contrastRequired,
      preparationNotes: widget.procedure.preparationInstructions,
      prescriptionFileName: _prescriptionName,
      paymentMethod: _payAtCenter ? 'pay_at_center' : 'online',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!res.success) {
      custom.SnackBarHelper.showError(
        context,
        res.error ?? 'Could not submit scan booking',
      );
      return;
    }

    Navigator.of(context).pop();
    custom.SnackBarHelper.showSuccess(
      context,
      'Scan request submitted. ${_payAtCenter ? 'Pay at the center after confirmation.' : 'Complete payment from My Bookings after the center confirms.'} '
      'You can also call the center if urgent.',
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final prep = widget.procedure.preparationInstructions;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.procedure.name,
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.center.displayName,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _callCenter,
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Call center'),
                ),
                if (prep != null && prep.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Preparation: $prep',
                      style: AppTextStyles.bodySmall.copyWith(height: 1.35),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Date', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDecorations.borderRadiusMd,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  leading: const Icon(Icons.event_rounded),
                  title: Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Select date',
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                Text('Time slot', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((slot) {
                    final selected = _selectedTimeSlot == slot;
                    return FilterChip(
                      label: Text(slot),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedTimeSlot = slot),
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Contrast required'),
                  value: _contrastRequired,
                  onChanged: (v) => setState(() => _contrastRequired = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pay at center'),
                  subtitle: const Text('Otherwise pay online after confirmation'),
                  value: _payAtCenter,
                  onChanged: (v) => setState(() => _payAtCenter = v),
                ),
                if (widget.procedure.prescriptionRequired) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickPrescription,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      _prescriptionName ?? 'Upload prescription',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Amount due: ₹$_total'
                  '${_discountAmount > 0 ? ' (saved ₹$_discountAmount)' : ''}',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                custom.CustomButton(
                  label: 'Request booking',
                  icon: Icons.check_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _confirmBooking,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
