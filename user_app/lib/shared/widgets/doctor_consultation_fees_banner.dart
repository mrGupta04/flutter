import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validation_utils.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';

/// Shows online and hospital visit charges for a doctor during booking.
class DoctorConsultationFeesBanner extends StatelessWidget {
  const DoctorConsultationFeesBanner({
    super.key,
    required this.doctor,
    this.highlightedType,
  });

  final DoctorModel doctor;
  final ConsultationType? highlightedType;

  @override
  Widget build(BuildContext context) {
    final onlineFee = doctor.offersOnlineConsult
        ? doctor.feeForConsultationType(ConsultationType.onlineConsult)
        : null;
    final visitFee = doctor.offersVisitSite
        ? doctor.feeForConsultationType(ConsultationType.visitSite)
        : null;
    final homeFee = doctor.offersBookHome
        ? doctor.feeForConsultationType(ConsultationType.bookHome)
        : null;

    if (onlineFee == null && visitFee == null && homeFee == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consultation charges',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          if (onlineFee != null && visitFee != null && homeFee != null)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FeeTile(
                        icon: Icons.videocam_rounded,
                        label: 'Online consult',
                        fee: onlineFee,
                        highlighted:
                            highlightedType == ConsultationType.onlineConsult,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FeeTile(
                        icon: Icons.local_hospital_rounded,
                        label: 'Hospital visit',
                        fee: visitFee,
                        highlighted:
                            highlightedType == ConsultationType.visitSite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _FeeTile(
                  icon: Icons.home_rounded,
                  label: 'Home visit',
                  fee: homeFee,
                  highlighted: highlightedType == ConsultationType.bookHome,
                  fullWidth: true,
                ),
              ],
            )
          else
            Row(
              children: [
                if (onlineFee != null)
                  Expanded(
                    child: _FeeTile(
                      icon: Icons.videocam_rounded,
                      label: 'Online consult',
                      fee: onlineFee,
                      highlighted:
                          highlightedType == ConsultationType.onlineConsult,
                    ),
                  ),
                if (onlineFee != null &&
                    (visitFee != null || homeFee != null))
                  const SizedBox(width: 10),
                if (visitFee != null)
                  Expanded(
                    child: _FeeTile(
                      icon: Icons.local_hospital_rounded,
                      label: 'Hospital visit',
                      fee: visitFee,
                      highlighted:
                          highlightedType == ConsultationType.visitSite,
                    ),
                  ),
                if (visitFee != null && homeFee != null)
                  const SizedBox(width: 10),
                if (homeFee != null && visitFee == null)
                  Expanded(
                    child: _FeeTile(
                      icon: Icons.home_rounded,
                      label: 'Home visit',
                      fee: homeFee,
                      highlighted: highlightedType == ConsultationType.bookHome,
                    ),
                  ),
                if (homeFee != null && visitFee != null)
                  Expanded(
                    child: _FeeTile(
                      icon: Icons.home_rounded,
                      label: 'Home visit',
                      fee: homeFee,
                      highlighted: highlightedType == ConsultationType.bookHome,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeeTile extends StatelessWidget {
  const _FeeTile({
    required this.icon,
    required this.label,
    required this.fee,
    required this.highlighted,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final int fee;
  final bool highlighted;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.white : AppColors.white.withValues(alpha: 0.7),
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.divider,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            FormattingUtils.formatConsultationFee(fee),
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
    return tile;
  }
}
