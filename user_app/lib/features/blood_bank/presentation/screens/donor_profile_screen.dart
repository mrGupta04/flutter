import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/blood_bank_repository.dart';
import '../../data/blood_bank_catalog.dart';

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final _repo = BloodBankRepository();
  final _name = TextEditingController();
  final _city = TextEditingController();
  String? _bloodGroup;
  String _contactPreference = 'in_app';
  bool _emergency = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _eligibilityStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _repo.getDonorProfile();
    if (!mounted) return;
    final data = res.data;
    setState(() {
      _loading = false;
      _error = res.success ? null : res.error;
      if (data != null) {
        _name.text = data['displayName'] as String? ?? '';
        _city.text = data['city'] as String? ?? '';
        _bloodGroup = data['bloodGroup'] as String?;
        _contactPreference = data['contactPreference'] as String? ?? 'in_app';
        _emergency = data['availableForEmergency'] as bool? ?? false;
        _eligibilityStatus = data['eligibilityStatus'] as String?;
      }
    });
  }

  Future<void> _save() async {
    final loggedIn = await ensureUserLoggedIn(
      context,
      message: 'Please log in or create an account before saving a donor profile.',
    );
    if (!loggedIn || !mounted) return;
    if (_bloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your blood group')),
      );
      return;
    }
    setState(() => _saving = true);
    final res = await _repo.saveDonorProfile({
      'displayName': _name.text.trim(),
      'bloodGroup': _bloodGroup,
      'city': _city.text.trim(),
      'contactPreference': _contactPreference,
      'availableForEmergency': _emergency,
      'eligibilityStatus': 'pending_screening',
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message ?? res.error ?? 'Saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a blood donor')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      'Eligibility is confirmed only after a blood bank screening. '
                      'This profile never declares you medically eligible.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (_eligibilityStatus != null)
                      Chip(label: Text('Status: ${_eligibilityStatus!.replaceAll('_', ' ')}')),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _bloodGroup,
                      decoration: const InputDecoration(labelText: 'Blood group'),
                      items: kBloodGroups
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _bloodGroup = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _contactPreference,
                      decoration: const InputDecoration(labelText: 'Contact preference'),
                      items: const [
                        DropdownMenuItem(value: 'in_app', child: Text('In-app only')),
                        DropdownMenuItem(value: 'phone', child: Text('Phone')),
                        DropdownMenuItem(value: 'both', child: Text('Both')),
                      ],
                      onChanged: (v) => setState(() => _contactPreference = v ?? 'in_app'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for emergency donor requests'),
                      subtitle: const Text(
                        'Your personal details stay hidden until you choose to respond.',
                      ),
                      value: _emergency,
                      onChanged: (v) => setState(() => _emergency = v),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save donor profile'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push(AppConstants.routeBloodDonorHistory),
                      child: const Text('My donation history'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.push(AppConstants.routeBloodDonorRequests),
                      child: const Text('Emergency donor requests'),
                    ),
                  ],
                ),
    );
  }
}
