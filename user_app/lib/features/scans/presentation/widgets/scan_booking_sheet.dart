import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/scan_center_model.dart';
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

class _ScanBookingSheet extends StatefulWidget {
  const _ScanBookingSheet({
    required this.center,
    required this.procedure,
  });

  final ScanCenterModel center;
  final ScanProcedure procedure;

  @override
  State<_ScanBookingSheet> createState() => _ScanBookingSheetState();
}

class _ScanBookingSheetState extends State<_ScanBookingSheet> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _payOnline = true;
  bool _isSubmitting = false;
  String? _prescriptionName;
  final _couponController = TextEditingController();

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

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
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

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();
    custom.SnackBarHelper.showSuccess(
      context,
      '${widget.procedure.name} booked at ${widget.center.displayName} '
      'for ${_formatDate(_selectedDate!)} at $_selectedTimeSlot. '
      '${_payOnline ? 'Payment link sent.' : 'Pay at center on arrival.'}',
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

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Book scan',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${widget.procedure.name} · ${widget.center.displayName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle('Date'),
                _DateTile(
                  label: _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'Select date',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                _SectionTitle('Time slot'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((slot) {
                    final selected = _selectedTimeSlot == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedTimeSlot = slot),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _SectionTitle('Doctor prescription'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file_rounded),
                  title: Text(
                    _prescriptionName ?? 'Upload prescription (optional)',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: TextButton(
                    onPressed: _pickPrescription,
                    child: const Text('Browse'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    hintText: 'Coupon code',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.local_offer_outlined),
                      onPressed: () {},
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle('Payment'),
                RadioListTile<bool>(
                  value: true,
                  groupValue: _payOnline,
                  onChanged: (v) => setState(() => _payOnline = v ?? true),
                  title: const Text('Pay online'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                if (widget.center.cashPaymentEnabled != false)
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _payOnline,
                    onChanged: (v) => setState(() => _payOnline = v ?? false),
                    title: const Text('Cash at center'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 12),
                if (_discountAmount > 0)
                  Row(
                    children: [
                      const Text('Offer discount'),
                      const Spacer(),
                      Text(
                        '-₹$_discountAmount',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.offer,
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹$_total',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                custom.CustomButton(
                  label: 'Confirm booking',
                  icon: Icons.check_rounded,
                  isLoading: _isSubmitting,
                  isEnabled: _selectedDate != null && _selectedTimeSlot != null,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey50,
      borderRadius: AppDecorations.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusMd,
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
