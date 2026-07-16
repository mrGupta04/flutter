import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';

/// Resolves the payable consultation amount (offer when lower than regular).
int? resolvePayableConsultationFee({
  required DoctorModel doctor,
  required ConsultationType type,
  int? slotsConsultationFee,
}) {
  final effective = doctor.effectiveFeeForConsultationType(type);
  if (slotsConsultationFee != null && slotsConsultationFee > 0) {
    if (effective != null && effective > 0 && effective < slotsConsultationFee) {
      return effective;
    }
    return slotsConsultationFee;
  }
  return effective;
}

/// Regular / discount / payable breakdown for doctor booking screens.
class ConsultationBookingPriceSummary extends StatelessWidget {
  const ConsultationBookingPriceSummary({
    super.key,
    required this.doctor,
    required this.consultationType,
    this.slotsConsultationFee,
  });

  final DoctorModel doctor;
  final ConsultationType consultationType;
  final int? slotsConsultationFee;

  @override
  Widget build(BuildContext context) {
    final regular = doctor.feeForConsultationType(consultationType);
    final payable = resolvePayableConsultationFee(
      doctor: doctor,
      type: consultationType,
      slotsConsultationFee: slotsConsultationFee,
    );
    if (payable == null || payable <= 0) return const SizedBox.shrink();

    final discount = (regular != null && regular > payable)
        ? regular - payable
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment summary',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Consultation fee',
            value: '₹${regular ?? payable}',
          ),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _PriceRow(
              label: 'Offer discount',
              value: '-₹$discount',
              valueColor: AppColors.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _PriceRow(
            label: 'Amount to pay',
            value: '₹$payable',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = (bold ? AppTextStyles.titleSmall : AppTextStyles.bodyMedium)
        .copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style.copyWith(
            color: valueColor ??
                (bold ? AppColors.primaryDark : AppColors.textPrimary),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
