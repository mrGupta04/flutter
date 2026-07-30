import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/healthcare_ui.dart';

/// Hub for managing all service-provider application queues.
class AdminServiceProviderManagementScreen extends StatelessWidget {
  const AdminServiceProviderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Service provider management')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Review, verify, and manage provider applications across every category.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          Text(
            'Other providers',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Nurses',
            subtitle: 'Sessions · payment · visit progress · final status',
            color: AppColors.secondary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDoctorSessions}?provider=nurse&service=home_visit',
            ),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.local_shipping_rounded,
            title: 'Ambulance',
            subtitle: 'Fleet docs · drivers · approve or reject',
            color: AppColors.primary,
            onTap: () => context.push(AppConstants.routeAdminAmbulanceList),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.bloodtype_rounded,
            title: 'Blood banks',
            subtitle: 'Licenses · inventory readiness · approve',
            color: AppColors.secondary,
            onTap: () => context.push(AppConstants.routeAdminBloodBankList),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.biotech_rounded,
            title: 'Diagnostic labs',
            subtitle: 'Sample · report submitted · accepted by user',
            color: AppColors.primary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDiagnosticSessions}?kind=lab',
            ),
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.radar_rounded,
            title: 'Scan / MRI centers',
            subtitle: 'Scan performed · report submitted · accepted by user',
            color: AppColors.secondary,
            onTap: () => context.push(
              '${AppConstants.routeAdminDiagnosticSessions}?kind=scan',
            ),
          ),
        ],
      ),
    );
  }
}
