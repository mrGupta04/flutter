import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validation_utils.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';
import 'healthcare_ui.dart';

/// Unified doctor booking options — price, context, and action in one card.
class DoctorConsultationBookingSection extends StatelessWidget {
  const DoctorConsultationBookingSection({
    super.key,
    required this.doctor,
    required this.onBook,
  });

  final DoctorModel doctor;
  final ValueChanged<ConsultationType> onBook;

  @override
  Widget build(BuildContext context) {
    final types = doctor.availableConsultationTypes;
    if (types.isEmpty) return const SizedBox.shrink();

    final showsPrescriptionNote = types.any(
      (type) =>
          type == ConsultationType.onlineConsult ||
          type == ConsultationType.bookHome,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MarketplaceSectionTitle(title: 'Book consultation'),
        for (var i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ConsultationOptionCard(
            type: types[i],
            fee: doctor.feeForConsultationType(types[i]),
            onTap: () => onBook(types[i]),
          ),
        ],
        if (showsPrescriptionNote) ...[
          const SizedBox(height: 12),
          const _PrescriptionIncludedNote(),
        ],
      ],
    );
  }
}

class _ConsultationOptionCard extends StatelessWidget {
  const _ConsultationOptionCard({
    required this.type,
    required this.fee,
    required this.onTap,
  });

  final ConsultationType type;
  final int? fee;
  final VoidCallback onTap;

  bool get _isHospitalVisit => type == ConsultationType.visitSite;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(type);
    final priceLabel = fee != null && fee! > 0
        ? FormattingUtils.formatConsultationFee(fee!)
        : 'Fee on request';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHospitalVisit
                  ? AppColors.divider
                  : AppColors.primary.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isHospitalVisit
                            ? AppColors.grey100
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        config.icon,
                        size: 22,
                        color: _isHospitalVisit
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      priceLabel,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.actionLabel,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _isHospitalVisit
                              ? AppColors.textPrimary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: _isHospitalVisit
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsultationOptionConfig {
  const _ConsultationOptionConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
}

_ConsultationOptionConfig _configFor(ConsultationType type) {
  switch (type) {
    case ConsultationType.onlineConsult:
      return const _ConsultationOptionConfig(
        icon: Icons.videocam_rounded,
        title: 'Online consult',
        subtitle: 'Video call from anywhere',
        actionLabel: 'Book online consult',
      );
    case ConsultationType.visitSite:
      return const _ConsultationOptionConfig(
        icon: Icons.local_hospital_rounded,
        title: 'Hospital visit',
        subtitle: 'Visit at clinic or hospital',
        actionLabel: 'Book hospital visit',
      );
    case ConsultationType.bookHome:
      return const _ConsultationOptionConfig(
        icon: Icons.home_rounded,
        title: 'Home visit',
        subtitle: 'Doctor visits you at home',
        actionLabel: 'Book home visit',
      );
  }
}

class _PrescriptionIncludedNote extends StatelessWidget {
  const _PrescriptionIncludedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.55),
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.description_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Digital prescription included with online and home consultations. '
              'It will appear in your profile and be emailed to you.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
