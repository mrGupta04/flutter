import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/admin_auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OneMgHeader(
            locationLabel: 'Admin panel',
            locationValue: auth.email ?? 'Provider verification',
            searchHint: 'Review pending applications...',
            trailing: const Icon(Icons.logout_rounded, size: 20),
            onTrailingTap: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppConstants.routeAdminLogin);
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const OfferPromoCard(
                    title: 'Provider verification',
                    subtitle:
                        'Review registrations · approve to publish on user app',
                    badge: 'ADMIN',
                  ),
                  const SizedBox(height: 16),
                  ServiceBenefitCard(
                    icon: Icons.rule_folder_rounded,
                    title: 'Approval Management',
                    subtitle: 'Approvers · workflow · SLA · audit logs',
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppConstants.routeApprovalManagement),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Service provider management',
                    subtitle:
                        'Online / home / hospital doctors · nurses · labs · MRI',
                    color: AppColors.secondary,
                    onTap: () => context.push(
                      AppConstants.routeAdminServiceProviderManagement,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.analytics_rounded,
                    title: 'Marketplace overview',
                    subtitle: 'Patients · bookings · revenue · pending KYC',
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppConstants.routeAdminOverview),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.videocam_rounded,
                    title: 'Online doctor sessions',
                    subtitle: 'Patient · doctor · payment · join times · status',
                    color: AppColors.primary,
                    onTap: () => context.push(
                      '${AppConstants.routeAdminDoctorSessions}?service=online',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.home_rounded,
                    title: 'Home visit doctor sessions',
                    subtitle: 'Patient · doctor · payment · visit status',
                    color: AppColors.secondary,
                    onTap: () => context.push(
                      '${AppConstants.routeAdminDoctorSessions}?service=home_visit',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.local_hospital_rounded,
                    title: 'Hospital visit doctor sessions',
                    subtitle: 'Patient · doctor · payment · visit status',
                    color: AppColors.primary,
                    onTap: () => context.push(
                      '${AppConstants.routeAdminDoctorSessions}?service=hospital_visit',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.health_and_safety_rounded,
                    title: 'Nurse sessions',
                    subtitle:
                        'Patient · nurse · payment · visit progress · status',
                    color: AppColors.secondary,
                    onTap: () => context.push(
                      '${AppConstants.routeAdminDoctorSessions}?provider=nurse&service=home_visit',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.local_shipping_rounded,
                    title: 'Ambulance applications',
                    subtitle: 'Needs review · verify or reject',
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppConstants.routeAdminAmbulanceList),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.bloodtype_rounded,
                    title: 'Blood bank applications',
                    subtitle: 'Needs review · verify or reject',
                    color: AppColors.secondary,
                    onTap: () =>
                        context.push(AppConstants.routeAdminBloodBankList),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.biotech_rounded,
                    title: 'Diagnostic lab sessions',
                    subtitle:
                        'Sample collected · report submitted · accepted by user',
                    color: AppColors.primary,
                    onTap: () => context.push(
                      '${AppConstants.routeAdminDiagnosticSessions}?kind=lab',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.radar_rounded,
                    title: 'MRI / scan sessions',
                    subtitle:
                        'Scan performed · report submitted · accepted by user',
                    color: AppColors.secondary,
                    onTap: () => context.push(
                      '${AppConstants.routeAdminDiagnosticSessions}?kind=scan',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.support_agent_rounded,
                    title: 'Support tickets',
                    subtitle: 'Patient help desk · status updates',
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppConstants.routeAdminSupportTickets),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.local_offer_outlined,
                    title: 'Coupons',
                    subtitle: 'Discount codes for marketplace',
                    color: AppColors.secondary,
                    onTap: () => context.push(AppConstants.routeAdminCoupons),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.view_carousel_outlined,
                    title: 'CMS banners',
                    subtitle: 'Home hero slides for user app',
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppConstants.routeAdminCmsBanners),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Refunds',
                    subtitle: 'Record refunds on paid bookings',
                    color: AppColors.primary,
                    onTap: () => context.push(AppConstants.routeAdminRefunds),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
