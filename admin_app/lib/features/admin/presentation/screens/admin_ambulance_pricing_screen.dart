import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/ambulance_registration_repository.dart';

class AdminAmbulancePricingScreen extends StatefulWidget {
  const AdminAmbulancePricingScreen({super.key});

  @override
  State<AdminAmbulancePricingScreen> createState() =>
      _AdminAmbulancePricingScreenState();
}

class _AdminAmbulancePricingScreenState
    extends State<AdminAmbulancePricingScreen> {
  final _repo = AmbulanceRegistrationRepository();
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final response = await _repo.adminPricing();
    if (!mounted) return;
    setState(() {
      _controller.text = const JsonEncoder.withIndent('  ').convert(response.data ?? {});
      _loading = false;
    });
  }

  Future<void> _save() async {
    try {
      final rules = jsonDecode(_controller.text) as Map<String, dynamic>;
      final response = await _repo.saveAdminPricing(rules);
      if (!mounted) return;
      if (response.success) {
        SnackBarHelper.showSuccess(context, 'Pricing saved');
      } else {
        SnackBarHelper.showError(context, response.error ?? 'Save failed');
      }
    } catch (err) {
      if (mounted) SnackBarHelper.showError(context, 'Invalid JSON: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance pricing'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Fare rules JSON',
                ),
              ),
            ),
    );
  }
}
