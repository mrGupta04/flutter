import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';

class LabBookingConfirmationScreen extends StatelessWidget {
  const LabBookingConfirmationScreen({
    super.key,
    required this.labName,
    required this.date,
    required this.slot,
    required this.total,
  });

  final String labName;
  final String date;
  final String slot;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Booking confirmed!',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your lab test booking at $labName is confirmed.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Lab', value: labName),
              _DetailRow(label: 'Date', value: date),
              _DetailRow(label: 'Time slot', value: slot),
              _DetailRow(label: 'Amount paid', value: '₹$total'),
              const Spacer(),
              CustomButton(
                label: 'View My Bookings',
                icon: Icons.event_note_rounded,
                onPressed: () => context.go(AppConstants.routeUserDashboard),
              ),
              const SizedBox(height: 10),
              CustomOutlineButton(
                label: 'Back to Home',
                icon: Icons.home_outlined,
                onPressed: () => context.go(AppConstants.routeUserHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
