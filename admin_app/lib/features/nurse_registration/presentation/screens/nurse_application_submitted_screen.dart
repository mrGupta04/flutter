import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/provider_document_status_section.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../../provider/provider/provider_status_sync.dart';

class NurseApplicationSubmittedScreen extends ConsumerStatefulWidget {
  const NurseApplicationSubmittedScreen({super.key});

  @override
  ConsumerState<NurseApplicationSubmittedScreen> createState() =>
      _NurseApplicationSubmittedScreenState();
}

class _NurseApplicationSubmittedScreenState
    extends ConsumerState<NurseApplicationSubmittedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(providerAuthProvider.notifier).refreshSession();
      await refreshProviderApplicationStatus(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = readProviderVerificationStatus(ref);
    final isVerified = status == VerificationStatus.verified;
    final isRejected = status == VerificationStatus.rejected;

    final timelineItems = [
      TimelineItem(
        title: 'Application received',
        subtitle: 'We got your nurse registration details',
        date: FormattingUtils.formatDate(DateTime.now()),
        icon: Icons.check_circle_rounded,
        isCompleted: true,
      ),
      TimelineItem(
        title: 'Admin review',
        subtitle: 'Our admin team is checking your credentials',
        icon: Icons.admin_panel_settings_rounded,
        isCompleted: status == VerificationStatus.underReview ||
            isVerified ||
            isRejected,
      ),
      TimelineItem(
        title: 'Listed on user app',
        subtitle: 'Patients can find you in the 1mg Care app',
        icon: Icons.verified_rounded,
        isCompleted: isVerified,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nurse application status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => refreshProviderApplicationStatus(ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplicationStatusHero(
              isVerified: isVerified,
              isRejected: isRejected,
            ),
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'Status timeline'),
            VerificationTimeline(items: timelineItems),
            if (!isVerified) ...[
              const SizedBox(height: 24),
              const ProviderDocumentStatusSection(),
            ],
            const SizedBox(height: 28),
            if (isVerified) ...[
              CustomButton(
                label: 'Open my dashboard',
                icon: Icons.dashboard_rounded,
                onPressed: () => openProviderDashboard(context, ref),
              ),
            ] else ...[
              CustomButton(
                label: 'View my profile',
                onPressed: () => openProviderDashboard(context, ref),
              ),
              const SizedBox(height: 12),
              CustomOutlineButton(
                label: 'Back to registration home',
                onPressed: () =>
                    context.go(AppConstants.routeProviderLanding),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
