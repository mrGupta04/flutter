import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/repositories/doctor_registration_repository.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/provider_document_status_section.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../../provider/provider/provider_status_sync.dart';

class ApplicationSubmittedScreen extends ConsumerStatefulWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  ConsumerState<ApplicationSubmittedScreen> createState() =>
      _ApplicationSubmittedScreenState();
}

class _ApplicationSubmittedScreenState
    extends ConsumerState<ApplicationSubmittedScreen> {
  bool _isRefreshing = false;
  bool _isUploadingDocument = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    await ref.read(providerAuthProvider.notifier).refreshSession();
    await refreshProviderApplicationStatus(ref);
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _reuploadDocument(DocumentType type) async {
    final doctorId = ref.read(providerAuthProvider).entityId ??
        await TokenStorage.instance.getDoctorId();
    if (doctorId == null || doctorId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to re-upload documents')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedDocumentFormats,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isUploadingDocument = true);
    final response = await DoctorRegistrationRepository().uploadDocument(
      doctorId: doctorId,
      filePath: result.files.single.path!,
      documentType: type,
    );
    if (!mounted) return;
    setState(() => _isUploadingDocument = false);

    if (response.success) {
      ref.invalidate(doctorDocumentsProvider);
      await _refreshStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppConstants.successDocumentUploaded)),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Upload failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = readProviderVerificationStatus(ref);
    final isVerified = status == VerificationStatus.verified;
    final isRejected = status == VerificationStatus.rejected;

    final timelineItems = [
      TimelineItem(
        title: 'Application received',
        subtitle: 'We got your details — sit back & relax',
        date: FormattingUtils.formatDate(DateTime.now()),
        icon: Icons.check_circle_rounded,
        isCompleted: true,
      ),
      TimelineItem(
        title: 'Admin review',
        subtitle: 'Application is in the admin queue for approval',
        icon: Icons.admin_panel_settings_rounded,
        isCompleted: status == VerificationStatus.underReview ||
            isVerified ||
            isRejected,
      ),
      TimelineItem(
        title: 'Go live on user app',
        subtitle: 'Your profile appears in the 1mg Care patient app',
        icon: Icons.verified_rounded,
        isCompleted: isVerified,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Application status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refreshStatus,
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
            const OfferPromoCard(
              title: 'What happens next?',
              subtitle: 'Track your application progress below',
              badge: 'TRACK',
              icon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'Status timeline'),
            VerificationTimeline(items: timelineItems),
            if (!isVerified) ...[
              const SizedBox(height: 24),
              ProviderDocumentStatusSection(
                onReuploadDocument: _reuploadDocument,
                isUploading: _isUploadingDocument,
              ),
            ],
            const SizedBox(height: 28),
            if (isVerified)
              CustomButton(
                label: 'Open practice dashboard',
                icon: Icons.dashboard_rounded,
                onPressed: () => openProviderDashboard(context, ref),
              )
            else ...[
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
