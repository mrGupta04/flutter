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
                    icon: Icons.people_alt_rounded,
                    title: 'Doctor applications',
                    subtitle: 'Needs review · verify or reject',
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppConstants.routeAdminDoctorList),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.health_and_safety_rounded,
                    title: 'Nurse applications',
                    subtitle: 'Needs review · verify or reject',
                    color: AppColors.secondary,
                    onTap: () => context.push(AppConstants.routeAdminNurseList),
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
                    title: 'Diagnostic lab applications',
                    subtitle: 'Review documents · approve or suspend',
                    color: AppColors.primary,
                    onTap: () => context.push(AppConstants.routeAdminLabList),
                  ),
                  const SizedBox(height: 10),
                  ServiceBenefitCard(
                    icon: Icons.radar_rounded,
                    title: 'Scan center applications',
                    subtitle: 'Review imaging services · approve or suspend',
                    color: AppColors.secondary,
                    onTap: () => context.push(AppConstants.routeAdminScanList),
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
