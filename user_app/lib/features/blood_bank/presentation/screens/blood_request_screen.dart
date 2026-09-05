import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/services/blood_order_payment_flow.dart';
import '../../data/blood_bank_catalog.dart';

class BloodRequestScreen extends ConsumerStatefulWidget {
  const BloodRequestScreen({
    super.key,
    required this.bloodBank,
    this.initialBloodGroup,
    this.initialComponentId,
    this.emergency = false,
  });

  final BloodBankModel bloodBank;
  final String? initialBloodGroup;
  final String? initialComponentId;
  final bool emergency;

  @override
  ConsumerState<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends ConsumerState<BloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentFlow = BloodOrderPaymentFlow();
  final _patientName = TextEditingController();
  final _age = TextEditingController();
  final _hospital = TextEditingController();
  final _hospitalAddress = TextEditingController();
  final _doctorName = TextEditingController();
  final _doctorContact = TextEditingController();
  final _mobile = TextEditingController();
  final _notes = TextEditingController();
  String? _bloodGroup;
  String? _componentId;
  String _gender = 'Male';
  int _units = 1;
  DateTime _requiredDate = DateTime.now().add(const Duration(days: 1));
  String _requiredTime = '10:00 AM';
  String _deliveryMethod = 'self_pickup';
  bool _submitting = false;
  String? _documentName;

  static const _times = ['8:00 AM', '10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM'];

  @override
  void initState() {
    super.initState();
    _bloodGroup = widget.initialBloodGroup ?? widget.bloodBank.bloodGroupsAvailable?.firstOrNull;
    _componentId = widget.initialComponentId ??
        widget.bloodBank.bloodComponents?.firstOrNull?.componentId ??
        'whole_blood';
    if (widget.bloodBank.hospitalDeliveryAvailable == true) {
      _deliveryMethod = 'hospital_delivery';
    }
  }

  @override
  void dispose() {
    _patientName.dispose();
    _age.dispose();
    _hospital.dispose();
    _hospitalAddress.dispose();
    _doctorName.dispose();
    _doctorContact.dispose();
    _mobile.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _bloodGroup == null || _componentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the required fields')),
      );
      return;
    }
    if (_units < 1) return;

    final loggedIn = await ensureUserLoggedIn(
      context,
      message: 'Please log in or create an account before requesting blood.',
    );
    if (!loggedIn || !mounted) return;

    if (widget.emergency) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm emergency request'),
          content: const Text(
            'Emergency request will notify eligible nearby blood banks immediately.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _submitting = true);
    try {
      final order = await _paymentFlow.placeOrderWithPayment(
        bloodBank: widget.bloodBank,
        orderPayload: {
          'bloodBankId': widget.bloodBank.id,
          'bloodGroup': _bloodGroup,
          'componentType': _componentId,
          'units': _units,
          'patientName': _patientName.text.trim(),
          'patientAge': int.tryParse(_age.text.trim()),
          'patientGender': _gender,
          'patientMobile': _mobile.text.trim(),
          'hospitalName': _hospital.text.trim(),
          'hospitalAddress': _hospitalAddress.text.trim(),
          'doctorName': _doctorName.text.trim(),
          'doctorContact': _doctorContact.text.trim(),
          'requiredDate': _requiredDate.toIso8601String(),
          'requiredTime': _requiredTime,
          'deliveryMethod': _deliveryMethod,
          'notes': _notes.text.trim(),
          'isEmergency': widget.emergency,
          'requestType': widget.emergency ? 'emergency' : 'normal',
        },
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (order != null) {
        context.push('${AppConstants.routeBloodOrderConfirmation}/${order.id}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.emergency ? 'Emergency blood request' : 'Request blood'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(widget.bloodBank.institutionName ?? 'Blood bank',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood group'),
              items: kBloodGroups
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _componentId,
              decoration: const InputDecoration(labelText: 'Component'),
              items: kBloodComponents
                  .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']!)))
                  .toList(),
              onChanged: (v) => setState(() => _componentId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _patientName,
              decoration: const InputDecoration(labelText: 'Patient name'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
              validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a valid age' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v ?? 'Male'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact number'),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Units'),
                const Spacer(),
                IconButton(
                  onPressed: _units > 1 ? () => setState(() => _units--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_units', style: AppTextStyles.titleMedium),
                IconButton(
                  onPressed: () => setState(() => _units++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required date'),
              subtitle: Text('${_requiredDate.day}/${_requiredDate.month}/${_requiredDate.year}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  initialDate: _requiredDate,
                );
                if (picked != null) setState(() => _requiredDate = picked);
              },
            ),
            DropdownButtonFormField<String>(
              value: _requiredTime,
              decoration: const InputDecoration(labelText: 'Required time'),
              items: _times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _requiredTime = v ?? _requiredTime),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hospital,
              decoration: const InputDecoration(labelText: 'Hospital name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hospitalAddress,
              decoration: const InputDecoration(labelText: 'Hospital address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doctorName,
              decoration: const InputDecoration(labelText: 'Doctor name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doctorContact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Doctor contact'),
            ),
            const SizedBox(height: 12),
            if (widget.bloodBank.homeDeliveryAvailable == true ||
                widget.bloodBank.hospitalDeliveryAvailable == true)
              DropdownButtonFormField<String>(
                value: _deliveryMethod,
                decoration: const InputDecoration(labelText: 'Collection method'),
                items: [
                  const DropdownMenuItem(value: 'self_pickup', child: Text('Pickup')),
                  if (widget.bloodBank.hospitalDeliveryAvailable == true)
                    const DropdownMenuItem(
                      value: 'hospital_delivery',
                      child: Text('Hospital delivery'),
                    ),
                  if (widget.bloodBank.homeDeliveryAvailable == true)
                    const DropdownMenuItem(value: 'home_delivery', child: Text('Home delivery')),
                ],
                onChanged: (v) => setState(() => _deliveryMethod = v ?? 'self_pickup'),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() => _documentName = result.files.single.name);
                }
              },
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(_documentName ?? 'Upload prescription / document'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Additional notes'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.emergency ? 'Send emergency request' : 'Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}
