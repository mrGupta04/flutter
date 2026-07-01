import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/blood_bank_dashboard_provider.dart';

class BloodBankDashboardScreen extends ConsumerStatefulWidget {
  const BloodBankDashboardScreen({super.key});

  @override
  ConsumerState<BloodBankDashboardScreen> createState() =>
      _BloodBankDashboardScreenState();
}

class _BloodBankDashboardScreenState extends ConsumerState<BloodBankDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bloodBankDashboardProvider.notifier).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(bloodBankDashboardProvider);
    final bank = dashboard.bloodBank;
    final isVerified =
        bank?.verificationStatus == VerificationStatus.verified ||
            bank?.isApproved == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blood bank dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: dashboard.isLoading
                ? null
                : () => ref.read(bloodBankDashboardProvider.notifier).refreshAll(),
          ),
        ],
      ),
      body: dashboard.isLoading && bank == null
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(children: [ShimmerProfileHeader(), ShimmerStatCard()]),
            )
          : dashboard.error != null && bank == null
              ? AppErrorWidget(
                  message: dashboard.error!,
                  onRetry: () =>
                      ref.read(bloodBankDashboardProvider.notifier).refreshAll(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(bloodBankDashboardProvider.notifier).refreshAll(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (bank != null && !isVerified)
                        const OfferPromoCard(
                          title: 'Verification pending',
                          subtitle: 'Your blood bank goes live after admin approval.',
                          icon: Icons.hourglass_top_rounded,
                        ),
                      if (bank != null) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFFB71C1C).withValues(alpha: 0.12),
                            child: const Icon(Icons.bloodtype_rounded,
                                color: Color(0xFFB71C1C)),
                          ),
                          title: Text(
                            bank.institutionName ?? 'Blood bank',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(bank.city ?? bank.address ?? ''),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const MarketplaceSectionTitle(title: 'Overview'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _StatCard('Total orders', '${dashboard.totalOrders}'),
                          _StatCard('Pending', '${dashboard.pendingOrders}'),
                          _StatCard('Completed', '${dashboard.completedOrders}'),
                          _StatCard('Revenue', '₹${dashboard.revenue}'),
                          _StatCard('Today', '${dashboard.todayOrders}'),
                          _StatCard('Emergency', '${dashboard.emergencyCount}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const MarketplaceSectionTitle(title: 'Quick actions'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ActionChip('Manage inventory', Icons.inventory_2_outlined),
                          _ActionChip('Manage pricing', Icons.payments_outlined),
                          _ActionChip('Manage offers', Icons.local_offer_outlined),
                          _ActionChip('Upload documents', Icons.upload_file_outlined),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const MarketplaceSectionTitle(title: 'Pending orders'),
                      if (dashboard.orders.isEmpty)
                        const Text('No orders yet.')
                      else
                        ...dashboard.orders
                            .where((o) => o['status'] == 'pending')
                            .take(5)
                            .map((order) => Card(
                                  child: ListTile(
                                    title: Text(
                                      '${order['bloodGroup']} · ${order['componentType']}',
                                    ),
                                    subtitle: Text(
                                      '${order['units']} units · ${order['patientName'] ?? 'Patient'}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline,
                                              color: Colors.green),
                                          onPressed: () => ref
                                              .read(bloodBankDashboardProvider.notifier)
                                              .updateOrderStatus(
                                                order['id'] as String,
                                                'accepted',
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined,
                                              color: Colors.red),
                                          onPressed: () => ref
                                              .read(bloodBankDashboardProvider.notifier)
                                              .updateOrderStatus(
                                                order['id'] as String,
                                                'rejected',
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                      const SizedBox(height: 20),
                      const MarketplaceSectionTitle(title: 'Emergency requests'),
                      if (dashboard.emergencyRequests.isEmpty)
                        const Text('No open emergency requests.')
                      else
                        ...dashboard.emergencyRequests.take(5).map(
                              (req) => Card(
                                color: const Color(0xFFFFEBEE),
                                child: ListTile(
                                  title: Text(
                                    '${req['bloodGroup']} · ${req['units']} units',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    '${req['patientName'] ?? ''} · ${req['hospitalName'] ?? ''}',
                                  ),
                                  trailing: TextButton(
                                    onPressed: () => ref
                                        .read(bloodBankDashboardProvider.notifier)
                                        .acceptEmergency(req['id'] as String),
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {},
    );
  }
}
