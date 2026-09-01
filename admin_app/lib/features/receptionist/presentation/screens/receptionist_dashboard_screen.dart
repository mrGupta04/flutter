import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/receptionist_model.dart';
import '../../provider/receptionist_providers.dart';

class ReceptionistDashboardScreen extends ConsumerWidget {
  const ReceptionistDashboardScreen({super.key});

  static const _filters = [
    ('today', "Today's visits"),
    ('upcoming', 'Upcoming'),
    ('pending', 'Pending verification'),
    ('verified', 'Verified'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(receptionistAuthProvider);
    final dash = ref.watch(receptionistDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receptionist Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(receptionistDashboardProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(receptionistAuthProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppConstants.routeProviderLanding);
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(receptionistDashboardProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Hello, ${auth.profile?.name ?? 'Receptionist'}',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Today's clinic visits",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _filters)
                  ChoiceChip(
                    label: Text(filter.$2),
                    selected: dash.filter == filter.$1,
                    onSelected: (_) => ref
                        .read(receptionistDashboardProvider.notifier)
                        .load(filter: filter.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (dash.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dash.error != null)
              AppErrorWidget(
                message: dash.error!,
                onRetry: () =>
                    ref.read(receptionistDashboardProvider.notifier).load(),
              )
            else if (dash.visits.isEmpty)
              const EmptyStateWidget(
                icon: Icons.event_busy_rounded,
                title: 'No visits in this view',
                message: 'Clinic appointments for this filter will appear here.',
              )
            else
              for (final visit in dash.visits) ...[
                _VisitCard(visit: visit),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _VisitCard extends ConsumerWidget {
  const _VisitCard({required this.visit});

  final ClinicVisitModel visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = _statusStyle(visit);
    return Material(
      color: AppColors.white,
      borderRadius: AppDecorations.borderRadiusLg,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: AppDecorations.borderRadiusLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage: visit.patientProfilePicture != null &&
                          visit.patientProfilePicture!.isNotEmpty
                      ? NetworkImage(visit.patientProfilePicture!)
                      : null,
                  child: visit.patientProfilePicture == null ||
                          visit.patientProfilePicture!.isEmpty
                      ? Text(
                          visit.patientName.isNotEmpty
                              ? visit.patientName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.patientName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        visit.label ??
                            (visit.slotStart != null
                                ? '${FormattingUtils.formatDate(visit.slotStart!)} · ${FormattingUtils.formatTime(visit.slotStart!)}'
                                : 'Scheduled visit'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(label: status.label, color: status.color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Booking ID: ${visit.id}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            if (visit.patientMobile != null &&
                visit.patientMobile!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                visit.patientMobile!,
                style: AppTextStyles.bodySmall,
              ),
            ],
            if (visit.visitReason != null &&
                visit.visitReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${visit.visitReason}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (visit.isVerified) ...[
              const SizedBox(height: 12),
              Text(
                'Patient Verified ✓',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else if (visit.canVerify) ...[
              const SizedBox(height: 12),
              CustomButton(
                label: 'Verify Patient',
                onPressed: () => _openVerifySheet(context, ref, visit),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

({String label, Color color}) _statusStyle(ClinicVisitModel visit) {
  switch (visit.displayStatus) {
    case 'VERIFIED':
      return (label: 'Verified ✓', color: AppColors.success);
    case 'CONSULTATION_STARTED':
      return (label: 'Consultation started', color: AppColors.primary);
    case 'COMPLETED':
      return (label: 'Completed', color: AppColors.success);
    case 'CANCELLED':
      return (label: 'Cancelled', color: AppColors.error);
    default:
      return (label: 'Pending verification', color: AppColors.warning);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<void> _openVerifySheet(
  BuildContext context,
  WidgetRef ref,
  ClinicVisitModel visit,
) async {
  final verified = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _VerifyOtpSheet(visit: visit),
  );
  if (verified != true || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Patient Verified Successfully'),
      content: const Text(
        'Patient has been successfully verified and marked as arrived.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _VerifyOtpSheet extends ConsumerStatefulWidget {
  const _VerifyOtpSheet({required this.visit});

  final ClinicVisitModel visit;

  @override
  ConsumerState<_VerifyOtpSheet> createState() => _VerifyOtpSheetState();
}

class _VerifyOtpSheetState extends ConsumerState<_VerifyOtpSheet> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focus = List.generate(4, (_) => FocusNode());
  String? _errorTitle;
  String? _errorMessage;
  bool _verifying = false;
  bool _regenerating = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  ({String title, String message}) _otpError(String message) {
    final m = message.toLowerCase();
    if (m.contains('expired')) {
      return (
        title: 'OTP Expired',
        message:
            'This verification code has expired. Please generate a new verification code.',
      );
    }
    if (m.contains('incorrect') || m.contains('invalid')) {
      return (
        title: 'Invalid OTP',
        message: message,
      );
    }
    if (m.contains('already been used')) {
      return (
        title: 'OTP already used',
        message: message,
      );
    }
    if (m.contains('locked') || m.contains('too many')) {
      return (
        title: 'Maximum attempts exceeded',
        message: message,
      );
    }
    if (m.contains('already verified')) {
      return (
        title: 'Patient already verified',
        message: message,
      );
    }
    if (m.contains('cancelled')) {
      return (
        title: 'Booking cancelled',
        message: message,
      );
    }
    if (m.contains('does not belong')) {
      return (
        title: 'Unauthorized access',
        message: message,
      );
    }
    return (title: 'Verification failed', message: message);
  }

  Future<void> _verify() async {
    if (_otp.length != 4 || _verifying) return;
    setState(() {
      _verifying = true;
      _errorTitle = null;
      _errorMessage = null;
    });
    final error = await ref.read(receptionistDashboardProvider.notifier).verify(
          bookingId: widget.visit.id,
          otp: _otp,
        );
    if (!mounted) return;
    setState(() => _verifying = false);
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    final mapped = _otpError(error);
    setState(() {
      _errorTitle = mapped.title;
      _errorMessage = mapped.message;
    });
  }

  Future<void> _requestNewOtp() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    final error =
        await ref.read(receptionistDashboardProvider.notifier).regenerateOtp(
              widget.visit.id,
            );
    if (!mounted) return;
    setState(() => _regenerating = false);
    if (error == null) {
      SnackBarHelper.showSuccess(
        context,
        'A new verification code was generated. Ask the patient to open their booking.',
      );
      setState(() {
        _errorTitle = null;
        _errorMessage = null;
        for (final c in _controllers) {
          c.clear();
        }
      });
      return;
    }
    final mapped = _otpError(error);
    setState(() {
      _errorTitle = mapped.title;
      _errorMessage = mapped.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify Patient Arrival',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text('Patient: ${visit.patientName}', style: AppTextStyles.bodyMedium),
          Text(
            'Appointment: ${visit.label ?? ''}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Booking ID: ${visit.id}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask the patient for the verification code shown in their booking.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (_errorTitle != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _errorTitle!,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage ?? '',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Container(
                width: 52,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focus[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  enabled: !_verifying,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (value) {
                    if (value.isNotEmpty && i < 3) {
                      _focus[i + 1].requestFocus();
                    }
                    if (value.isEmpty && i > 0) {
                      _focus[i - 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Verify OTP',
            isLoading: _verifying,
            isEnabled: _otp.length == 4 && !_verifying,
            onPressed: _verify,
          ),
          TextButton(
            onPressed: _regenerating ? null : _requestNewOtp,
            child: Text(
              _regenerating ? 'Generating new code…' : 'Request new OTP',
            ),
          ),
          TextButton(
            onPressed: _verifying ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
