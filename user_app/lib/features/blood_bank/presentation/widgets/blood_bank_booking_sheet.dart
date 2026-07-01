import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/services/blood_order_payment_flow.dart';
import '../../data/blood_bank_catalog.dart';

Future<void> showBloodBankBookingSheet(
  BuildContext context, {
  required BloodBankModel bloodBank,
  String? initialBloodGroup,
  String? initialComponentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BloodBankBookingSheet(
      bloodBank: bloodBank,
      initialBloodGroup: initialBloodGroup,
      initialComponentId: initialComponentId,
    ),
  );
}

class _BloodBankBookingSheet extends ConsumerStatefulWidget {
  const _BloodBankBookingSheet({
    required this.bloodBank,
    this.initialBloodGroup,
    this.initialComponentId,
  });

  final BloodBankModel bloodBank;
  final String? initialBloodGroup;
  final String? initialComponentId;

  @override
  ConsumerState<_BloodBankBookingSheet> createState() =>
      _BloodBankBookingSheetState();
}

class _BloodBankBookingSheetState extends ConsumerState<_BloodBankBookingSheet> {
  final _paymentFlow = BloodOrderPaymentFlow();
  String? _bloodGroup;
  String? _componentId;
  int _units = 1;
  String _deliveryMethod = 'self_pickup';
  bool _payOnline = true;
  bool _isSubmitting = false;
  String? _prescriptionName;
  DateTime? _deliveryDate;
  String? _timeSlot;
  final _patientNameController = TextEditingController();
  final _patientMobileController = TextEditingController();
  final _couponController = TextEditingController();

  static const _timeSlots = [
    '8:00 AM', '10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _bloodGroup = widget.initialBloodGroup ??
        widget.bloodBank.bloodGroupsAvailable?.firstOrNull;
    _componentId = widget.initialComponentId ??
        widget.bloodBank.bloodComponents?.firstOrNull?.componentId;
    _deliveryDate = DateTime.now().add(const Duration(days: 1));
    _timeSlot = _timeSlots.first;
    if (widget.bloodBank.homeDeliveryAvailable == true) {
      _deliveryMethod = 'home_delivery';
    }
  }

  @override
  void dispose() {
    _paymentFlow.dispose();
    _patientNameController.dispose();
    _patientMobileController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  BloodComponentPricing? get _component => widget.bloodBank.bloodComponents
      ?.where((c) => c.componentId == _componentId)
      .firstOrNull;

  int get _basePrice => (_component?.effectivePrice ?? 0) * _units;

  int get _discountAmount {
    final offer = widget.bloodBank.activeOffer;
    if (offer == null) return 0;
    if (offer.discountType == 'percentage' && offer.discountValue != null) {
      return (_basePrice * offer.discountValue! / 100).round();
    }
    if (offer.discountType == 'flat' && offer.discountValue != null) {
      return offer.discountValue!.round();
    }
    return 0;
  }

  int get _total => (_basePrice - _discountAmount).clamp(0, _basePrice);

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.name.isNotEmpty) {
      setState(() => _prescriptionName = result.files.single.name);
    }
  }

  Future<void> _submit() async {
    if (_bloodGroup == null || _componentId == null) return;
    if (_patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = await _paymentFlow.placeOrderWithPayment(
        bloodBank: widget.bloodBank,
        orderPayload: {
          'bloodBankId': widget.bloodBank.id,
          'bloodGroup': _bloodGroup,
          'componentType': _componentId,
          'units': _units,
          'patientName': _patientNameController.text.trim(),
          'patientMobile': _patientMobileController.text.trim(),
          'deliveryMethod': _deliveryMethod,
          'deliveryDate': _deliveryDate?.toIso8601String(),
          'deliveryTimeSlot': _timeSlot,
          'couponCode': _couponController.text.trim().isEmpty
              ? null
              : _couponController.text.trim(),
          'paymentMethod': _payOnline ? 'online' : 'cash',
        },
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (order != null) {
        Navigator.pop(context);
        context.push(
          '${AppConstants.routeBloodOrderConfirmation}/${order.id}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final bank = widget.bloodBank;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order blood',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(bank.displayName, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 16),
                    Text('Blood group', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (bank.bloodGroupsAvailable ?? kBloodGroups)
                          .map((g) => ChoiceChip(
                                label: Text(g),
                                selected: _bloodGroup == g,
                                onSelected: (_) => setState(() => _bloodGroup = g),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Component', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 8),
                    ...kBloodComponents.map((c) {
                      final pricing = bank.bloodComponents
                          ?.where((p) => p.componentId == c['id'])
                          .firstOrNull;
                      return RadioListTile<String>(
                        value: c['id']!,
                        groupValue: _componentId,
                        onChanged: (v) => setState(() => _componentId = v),
                        title: Text(c['name']!),
                        subtitle: pricing != null
                            ? Text('₹${pricing.effectivePrice}')
                            : null,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Units', style: AppTextStyles.labelSmall),
                        const Spacer(),
                        IconButton(
                          onPressed: _units > 1
                              ? () => setState(() => _units--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_units', style: AppTextStyles.titleSmall),
                        IconButton(
                          onPressed: () => setState(() => _units++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _patientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Patient name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _patientMobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickPrescription,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _prescriptionName ?? 'Upload prescription (if required)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Delivery method', style: AppTextStyles.labelSmall),
                    if (bank.homeDeliveryAvailable == true)
                      RadioListTile<String>(
                        value: 'home_delivery',
                        groupValue: _deliveryMethod,
                        onChanged: (v) => setState(() => _deliveryMethod = v!),
                        title: const Text('Home delivery'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    RadioListTile<String>(
                      value: 'self_pickup',
                      groupValue: _deliveryMethod,
                      onChanged: (v) => setState(() => _deliveryMethod = v!),
                      title: const Text('Self pickup'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (bank.hospitalDeliveryAvailable == true)
                      RadioListTile<String>(
                        value: 'hospital_delivery',
                        groupValue: _deliveryMethod,
                        onChanged: (v) => setState(() => _deliveryMethod = v!),
                        title: const Text('Hospital delivery'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _timeSlot,
                      decoration: const InputDecoration(
                        labelText: 'Time slot',
                        border: OutlineInputBorder(),
                      ),
                      items: _timeSlots
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _timeSlot = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        labelText: 'Coupon code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (bank.cashPaymentEnabled == true) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _payOnline,
                        onChanged: (v) => setState(() => _payOnline = v),
                        title: const Text('Pay online'),
                        subtitle: Text(_payOnline ? 'Online payment' : 'Cash on delivery'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppDecorations.borderRadiusMd,
                      ),
                      child: Column(
                        children: [
                          _PriceRow(label: 'Base', amount: _basePrice),
                          if (_discountAmount > 0)
                            _PriceRow(
                              label: 'Discount',
                              amount: -_discountAmount,
                              color: AppColors.offer,
                            ),
                          const Divider(),
                          _PriceRow(
                            label: 'Total',
                            amount: _total,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: custom.CustomButton(
                label: _isSubmitting ? 'Placing order...' : 'Place order',
                onPressed: _isSubmitting ? () {} : _submit,
                isEnabled: !_isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.bold = false,
    this.color,
  });

  final String label;
  final int amount;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: bold
              ? AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)
              : AppTextStyles.bodySmall,
        ),
        const Spacer(),
        Text(
          '₹$amount',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
