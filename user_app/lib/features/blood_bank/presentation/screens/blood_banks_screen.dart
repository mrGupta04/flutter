import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../data/blood_bank_catalog.dart';

class BloodBanksScreen extends ConsumerWidget {
  const BloodBanksScreen({super.key, this.initialBloodGroup});

  final String? initialBloodGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blood Bank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'My requests',
            onPressed: () => context.push(AppConstants.routeMyBloodRequests),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _EmergencyBanner(
            onRequest: () => context.push(AppConstants.routeEmergencyBloodRequest),
          ),
          const SizedBox(height: 20),
          const MarketplaceSectionTitle(title: 'How can we help?'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ServiceBenefitCard(
                  title: 'Find Blood',
                  subtitle: 'Search nearby banks',
                  icon: Icons.search_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(
                    initialBloodGroup != null
                        ? '${AppConstants.routeBloodBankSearch}?bloodGroup=$initialBloodGroup'
                        : AppConstants.routeBloodBankSearch,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ServiceBenefitCard(
                  title: 'Donate Blood',
                  subtitle: 'Become a donor',
                  icon: Icons.volunteer_activism_outlined,
                  color: const Color(0xFFB71C1C),
                  onTap: () => context.push(AppConstants.routeBloodDonorProfile),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ServiceBenefitCard(
            title: 'My Blood Requests',
            subtitle: 'Track status, reservations and collection',
            icon: Icons.timeline_rounded,
            color: AppColors.info,
            onTap: () => context.push(AppConstants.routeMyBloodRequests),
          ),
          const SizedBox(height: 24),
          const MarketplaceSectionTitle(title: 'Search by blood group'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kBloodGroups.map((group) {
              return ActionChip(
                label: Text(group, style: const TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => context.push(
                  '${AppConstants.routeBloodBankSearch}?bloodGroup=$group',
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const MarketplaceSectionTitle(title: 'Components'),
          const SizedBox(height: 12),
          ...kBloodComponents.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.bloodtype_rounded, color: Color(0xFFB71C1C)),
                title: Text(c['name']!),
                subtitle: const Text('Find banks that publish this component'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(
                  '${AppConstants.routeBloodBankSearch}?componentType=${c['id']}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Availability shown by blood banks is for search only. '
            'Professional typing and crossmatching are always required before transfusion.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need blood urgently?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Notify eligible nearby blood banks immediately.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB71C1C),
            ),
            onPressed: onRequest,
            child: const Text('Request Blood Now'),
          ),
        ],
      ),
    );
  }
}
