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
import '../../../../shared/widgets/healthcare_ui.dart';

class ScanApplicationSubmittedScreen extends ConsumerStatefulWidget {
  const ScanApplicationSubmittedScreen({super.key});

  @override
  ConsumerState<ScanApplicationSubmittedScreen> createState() =>
      _ScanApplicationSubmittedScreenState();
}

class _ScanApplicationSubmittedScreenState
    extends ConsumerState<ScanApplicationSubmittedScreen> {
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
        title: const Text('Scan center application status'),
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
            const SizedBox(height: 24),
            CustomButton(
              label: isVerified ? 'Open my dashboard' : 'View application',
              icon: Icons.dashboard_rounded,
              onPressed: () => openProviderDashboard(context, ref),
            ),
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
