import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/nurse_registration_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nurseRegistrationProvider.notifier).refreshFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nurse = ref.watch(nurseRegistrationProvider).nurse;
    final isVerified =
        nurse?.verificationStatus == VerificationStatus.verified;

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
        isCompleted: nurse?.verificationStatus ==
                VerificationStatus.underReview ||
            isVerified,
      ),
      TimelineItem(
        title: 'Listed in marketplace',
        subtitle: 'Patients can find you in 1mg Care',
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
            onPressed: () =>
                ref.read(nurseRegistrationProvider.notifier).refreshFromApi(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isVerified
                      ? AppColors.gradientSuccess
                      : [AppColors.secondary, AppColors.primaryDark],
                ),
                borderRadius: AppDecorations.borderRadiusXl,
                boxShadow: AppDecorations.softShadow(opacity: 0.12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      size: 48,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVerified ? 'You\'re live!' : 'Verification pending',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVerified
                        ? 'Your profile is visible in the patient marketplace'
                        : 'Usually takes 24–48 hrs · admin reviews your application',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.95),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'Status timeline'),
            VerificationTimeline(items: timelineItems),
            const SizedBox(height: 28),
            if (isVerified)
              CustomOutlineButton(
                label: 'Browse care listings',
                icon: Icons.search_rounded,
                onPressed: () =>
                    context.go('${AppConstants.routeCareListing}?role=nurse'),
              )
            else
              CustomOutlineButton(
                label: 'Back to registration home',
                onPressed: () =>
                    context.go(AppConstants.routeProviderLanding),
              ),
          ],
        ),
      ),
    );
  }
}
