import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/blood_bank_repository.dart';

class BloodDonationCampsScreen extends ConsumerStatefulWidget {
  const BloodDonationCampsScreen({super.key});

  @override
  ConsumerState<BloodDonationCampsScreen> createState() =>
      _BloodDonationCampsScreenState();
}

class _BloodDonationCampsScreenState
    extends ConsumerState<BloodDonationCampsScreen> {
  final _repo = BloodBankRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _camps = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final city = ref.read(userLocationProvider).city;
    final res = await _repo.listDonationCamps(city: city);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = res.success ? null : (res.error ?? 'Unable to load donation camps');
      _camps = res.data ?? const [];
    });
  }

  Future<void> _register(Map<String, dynamic> camp) async {
    final loggedIn = await ensureUserLoggedIn(
      context,
      message: 'Please log in to register for a donation camp.',
    );
    if (!loggedIn || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Book donation slot'),
        content: const Text(
          'This registers your interest. The blood bank confirms medical eligibility in person. '
          'This app does not approve you as a donor automatically.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Register')),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await _repo.registerForCamp(camp['id'] as String);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.error ?? res.message ?? 'Registered')),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Donate Blood')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      Text(
                        'Find nearby donation camps. Eligibility is always confirmed by the blood bank.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      if (_camps.isEmpty)
                        Text(
                          'No donation camps nearby. Check again soon or visit a verified blood bank.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        )
                      else
                        ..._camps.map((camp) => _CampCard(
                              camp: camp,
                              onRegister: () => _register(camp),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _CampCard extends StatelessWidget {
  const _CampCard({required this.camp, required this.onRegister});

  final Map<String, dynamic> camp;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${camp['date'] ?? ''}');
    final dateLabel = date == null ? '' : DateFormat('EEE, d MMM').format(date.toLocal());
    final seats = camp['seatsLeft'] ?? camp['capacity'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              camp['title']?.toString() ?? 'Donation camp',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              [
                dateLabel,
                if (camp['startTime'] != null) '${camp['startTime']}–${camp['endTime'] ?? ''}',
                camp['address'] ?? camp['city'],
              ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' · '),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            if (camp['contact'] != null) ...[
              const SizedBox(height: 4),
              Text('Contact: ${camp['contact']}', style: AppTextStyles.labelSmall),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  seats == null ? 'Registration open' : '$seats slots left',
                  style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onRegister,
                  child: const Text('Book Donation Slot'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
