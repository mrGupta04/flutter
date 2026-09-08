import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/ambulance_registration_repository.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';

class AmbulanceDashboardScreen extends StatefulWidget {
  const AmbulanceDashboardScreen({super.key});

  @override
  State<AmbulanceDashboardScreen> createState() =>
      _AmbulanceDashboardScreenState();
}

class _AmbulanceDashboardScreenState extends State<AmbulanceDashboardScreen> {
  final _repo = AmbulanceRegistrationRepository();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await _repo.getDashboard();
    if (!mounted) return;
    setState(() {
      _data = response.data;
      _error = response.success ? null : response.error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = (_data?['stats'] as Map<String, dynamic>?) ?? {};
    final provider = (_data?['provider'] as Map<String, dynamic>?) ?? {};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ambulance dashboard'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(children: [ShimmerProfileHeader(), ShimmerStatCard()]),
            )
          : _error != null && _data == null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x33B71C1C),
                          child: Icon(Icons.emergency, color: Color(0xFFB71C1C)),
                        ),
                        title: Text(
                          provider['serviceName']?.toString() ?? 'Ambulance provider',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(provider['city']?.toString() ?? ''),
                      ),
                      const MarketplaceSectionTitle(title: 'Overview'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.45,
                        children: [
                          _stat('Available ambulances', stats['availableAmbulances']),
                          _stat('Active trips', stats['activeTrips']),
                          _stat('Emergency requests', stats['emergencyRequests']),
                          _stat('Scheduled trips', stats['scheduledTrips']),
                          _stat('Drivers online', stats['driversOnline']),
                          _stat('Today\'s trips', stats['completedToday']),
                          _stat('Earnings today', '₹${stats['earningsToday'] ?? 0}'),
                          _stat('Fleet size', stats['totalAmbulances']),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const MarketplaceSectionTitle(title: 'Quick actions'),
                      ServiceBenefitCard(
                        title: 'Operations',
                        subtitle: 'Requests, fleet, drivers and trips',
                        icon: Icons.dashboard_customize_outlined,
                        color: const Color(0xFFB71C1C),
                        onTap: () => context.push(AppConstants.routeAmbulanceOperations),
                      ),
                      const SizedBox(height: 8),
                      ServiceBenefitCard(
                        title: 'Driver mode',
                        subtitle: 'Go online and manage the active trip',
                        icon: Icons.directions_car_filled,
                        color: AppColors.primary,
                        onTap: () => context.push(AppConstants.routeAmbulanceDriverMode),
                      ),
                      const SizedBox(height: 16),
                      const MarketplaceSectionTitle(title: 'Your trip pricing'),
                      const SizedBox(height: 8),
                      _PricingCard(
                        provider: provider,
                        onSaved: _load,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _stat(String label, dynamic value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatefulWidget {
  const _PricingCard({required this.provider, required this.onSaved});

  final Map<String, dynamic> provider;
  final Future<void> Function() onSaved;

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  late final TextEditingController _base;
  late final TextEditingController _perKm;
  late final TextEditingController _min;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _base = TextEditingController(text: '${widget.provider['baseFare'] ?? 400}');
    _perKm = TextEditingController(text: '${widget.provider['perKm'] ?? 20}');
    _min = TextEditingController(text: '${widget.provider['minFare'] ?? 0}');
  }

  @override
  void didUpdateWidget(covariant _PricingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      _base.text = '${widget.provider['baseFare'] ?? 400}';
      _perKm.text = '${widget.provider['perKm'] ?? 20}';
      _min.text = '${widget.provider['minFare'] ?? 0}';
    }
  }

  @override
  void dispose() {
    _base.dispose();
    _perKm.dispose();
    _min.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final response = await AmbulanceRegistrationRepository().updateOperations({
      'baseFare': double.tryParse(_base.text.trim()) ?? 0,
      'perKm': double.tryParse(_perKm.text.trim()) ?? 0,
      'minFare': double.tryParse(_min.text.trim()) ?? 0,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (response.success) {
      SnackBarHelper.showSuccess(context, 'Pricing saved. Bookings will use ₹/km.');
      await widget.onSaved();
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Could not save pricing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Patients are charged your base fare plus distance × per-km rate.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _base,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Base fare (₹)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _perKm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price per km (₹)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _min,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minimum fare (₹, optional)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save pricing'),
            ),
          ],
        ),
      ),
    );
  }
}
