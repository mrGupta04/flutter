import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/blood_bank_repository.dart';
import '../../data/blood_bank_catalog.dart';

class EmergencyBloodRequestScreen extends StatefulWidget {
  const EmergencyBloodRequestScreen({super.key});

  @override
  State<EmergencyBloodRequestScreen> createState() =>
      _EmergencyBloodRequestScreenState();
}

class _EmergencyBloodRequestScreenState extends State<EmergencyBloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  String? _bloodGroup;
  int _units = 1;
  String _requiredWithin = '1 hour';
  bool _isSubmitting = false;

  static const _urgencyOptions = ['30 minutes', '1 hour', '2 hours', '4 hours'];

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _bloodGroup == null) {
      if (_bloodGroup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a blood group')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    final repository = BloodBankRepository();
    final response = await repository.createEmergencyRequest({
      'bloodGroup': _bloodGroup,
      'units': _units,
      'patientName': _patientNameController.text.trim(),
      'hospitalName': _hospitalController.text.trim(),
      'contactNumber': _contactController.text.trim(),
      'requiredWithin': _requiredWithin,
      'additionalNotes': _notesController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Emergency request sent'),
          content: const Text(
            'Nearby blood banks have been notified. '
            'You will be contacted shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppConstants.routeBloodBankSearch);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Request failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency blood request'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: Color(0xFFB71C1C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'For life-threatening emergencies, call emergency services immediately.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFB71C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Blood group', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kBloodGroups
                    .map((g) => ChoiceChip(
                          label: Text(g),
                          selected: _bloodGroup == g,
                          onSelected: (_) => setState(() => _bloodGroup = g),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Units required', style: AppTextStyles.labelLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: _units > 1 ? () => setState(() => _units--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_units'),
                  IconButton(
                    onPressed: () => setState(() => _units++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Hospital name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _requiredWithin,
                decoration: const InputDecoration(
                  labelText: 'Required within',
                  border: OutlineInputBorder(),
                ),
                items: _urgencyOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => setState(() => _requiredWithin = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: _isSubmitting ? 'Sending...' : 'Send emergency request',
                onPressed: _submit,
                isEnabled: !_isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
