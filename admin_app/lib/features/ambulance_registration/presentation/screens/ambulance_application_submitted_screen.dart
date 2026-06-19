import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../../provider/provider/provider_status_sync.dart';
import '../../../../shared/widgets/provider_document_status_section.dart';

class AmbulanceApplicationSubmittedScreen extends ConsumerStatefulWidget {
  const AmbulanceApplicationSubmittedScreen({super.key});

  @override
  ConsumerState<AmbulanceApplicationSubmittedScreen> createState() =>
      _AmbulanceApplicationSubmittedScreenState();
}

class _AmbulanceApplicationSubmittedScreenState
    extends ConsumerState<AmbulanceApplicationSubmittedScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ambulance application status'),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isVerified
                      ? AppColors.gradientSuccess
                      : [AppColors.secondary, AppColors.primaryDark],
                ),
                borderRadius: AppDecorations.borderRadiusXl,
              ),
              child: Column(
                children: [
                  Icon(
                    isVerified
                        ? Icons.verified_rounded
                        : Icons.local_shipping_rounded,
                    size: 48,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVerified
                        ? 'You\'re live!'
                        : isRejected
                            ? 'Application not approved'
                            : 'Verification pending',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVerified
                        ? 'Your ambulance service is on the user app'
                        : isRejected
                            ? 'Contact support for details'
                            : 'Admin will review within 24–48 hours',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.95),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isVerified) const ProviderDocumentStatusSection(),
            if (!isVerified) const SizedBox(height: 24),
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
            ],
            const SizedBox(height: 12),
            CustomOutlineButton(
              label: 'Back to registration home',
              onPressed: () => context.go(AppConstants.routeProviderLanding),
            ),
          ],
        ),
      ),
    );
  }
}
