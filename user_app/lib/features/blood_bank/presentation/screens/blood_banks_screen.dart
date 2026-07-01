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
        title: const Text('Blood banks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_rounded, color: Color(0xFFB71C1C)),
            onPressed: () => context.push(AppConstants.routeEmergencyBloodRequest),
            tooltip: 'Emergency request',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Find verified blood banks near you',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Order blood online or visit in person',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const MarketplaceSectionTitle(title: 'Browse by blood group'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kBloodGroups.map((group) {
              return ActionChip(
                label: Text(group),
                onPressed: () => context.push(
                  '${AppConstants.routeBloodBankSearch}?bloodGroup=$group',
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const MarketplaceSectionTitle(title: 'Blood components'),
          const SizedBox(height: 12),
          ...kBloodComponents.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.bloodtype_rounded, color: Color(0xFFB71C1C)),
                  title: Text(c['name']!),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    '${AppConstants.routeBloodBankSearch}?componentType=${c['id']}',
                  ),
                ),
              )),
          const SizedBox(height: 16),
          ServiceBenefitCard(
            title: 'Search all blood banks',
            subtitle: 'Filter by city, availability, emergency supply & more',
            icon: Icons.search_rounded,
            color: AppColors.primary,
            onTap: () => context.push(
              initialBloodGroup != null
                  ? '${AppConstants.routeBloodBankSearch}?bloodGroup=$initialBloodGroup'
                  : AppConstants.routeBloodBankSearch,
            ),
          ),
        ],
      ),
    );
  }
}
