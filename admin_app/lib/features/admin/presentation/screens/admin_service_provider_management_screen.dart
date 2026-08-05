import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/healthcare_ui.dart';

enum _ProviderCategory {
  doctors,
  nurses,
  ambulance,
  bloodBanks,
  labs,
  scans,
}

/// Hub for managing all service-provider application queues.
class AdminServiceProviderManagementScreen extends StatefulWidget {
  const AdminServiceProviderManagementScreen({super.key});

  @override
  State<AdminServiceProviderManagementScreen> createState() =>
      _AdminServiceProviderManagementScreenState();
}

class _AdminServiceProviderManagementScreenState
    extends State<AdminServiceProviderManagementScreen> {
  _ProviderCategory _selected = _ProviderCategory.doctors;

  static const _categories = <(_ProviderCategory, String, IconData)>[
    (_ProviderCategory.doctors, 'Doctors', Icons.medical_services_rounded),
    (_ProviderCategory.nurses, 'Nurses', Icons.health_and_safety_rounded),
    (_ProviderCategory.ambulance, 'Ambulance', Icons.local_shipping_rounded),
    (_ProviderCategory.bloodBanks, 'Blood banks', Icons.bloodtype_rounded),
    (_ProviderCategory.labs, 'Labs', Icons.biotech_rounded),
    (_ProviderCategory.scans, 'Scan / MRI', Icons.radar_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Service provider management')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Review, verify, and manage provider applications across every category.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < _categories.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _ProviderChip(
                    label: _categories[i].$2,
                    icon: _categories[i].$3,
                    selected: _selected == _categories[i].$1,
                    onTap: () => setState(() => _selected = _categories[i].$1),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: _buildCategoryContent(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryContent(BuildContext context) {
    switch (_selected) {
      case _ProviderCategory.doctors:
        return [
          Text(
            'Doctors by service',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.videocam_rounded,
            title: 'Online doctors',
            subtitle: 'Sessions · payment · join times · final status',
            color: AppColors.primary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDoctorSessions}?service=online',
            ),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.home_rounded,
            title: 'Home visit doctors',
            subtitle: 'Sessions · payment · visit progress · final status',
            color: AppColors.secondary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDoctorSessions}?service=home_visit',
            ),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.local_hospital_rounded,
            title: 'Hospital visit doctors',
            subtitle: 'Sessions · payment · verification · final status',
            color: AppColors.primary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDoctorSessions}?service=hospital_visit',
            ),
          ),
        ];
      case _ProviderCategory.nurses:
        return [
          ServiceBenefitCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Nurses',
            subtitle: 'Sessions · payment · visit progress · final status',
            color: AppColors.secondary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDoctorSessions}?provider=nurse&service=home_visit',
            ),
          ),
        ];
      case _ProviderCategory.ambulance:
        return [
          ServiceBenefitCard(
            icon: Icons.local_shipping_rounded,
            title: 'Ambulance',
            subtitle: 'Fleet docs · drivers · approve or reject',
            color: AppColors.primary,
            onTap: () => context.push(AppConstants.routeAdminAmbulanceList),
          ),
        ];
      case _ProviderCategory.bloodBanks:
        return [
          ServiceBenefitCard(
            icon: Icons.bloodtype_rounded,
            title: 'Blood banks',
            subtitle: 'Licenses · inventory readiness · approve',
            color: AppColors.secondary,
            onTap: () => context.push(AppConstants.routeAdminBloodBankList),
          ),
        ];
      case _ProviderCategory.labs:
        return [
          ServiceBenefitCard(
            icon: Icons.biotech_rounded,
            title: 'Diagnostic labs',
            subtitle: 'Sample · report submitted · accepted by user',
            color: AppColors.primary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDiagnosticSessions}?kind=lab',
            ),
          ),
        ];
      case _ProviderCategory.scans:
        return [
          ServiceBenefitCard(
            icon: Icons.radar_rounded,
            title: 'Scan / MRI centers',
            subtitle: 'Scan performed · report submitted · accepted by user',
            color: AppColors.secondary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDiagnosticSessions}?kind=scan',
            ),
          ),
        ];
    }
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? AppColors.white : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.white,
      backgroundColor: AppColors.white,
      showCheckmark: false,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
