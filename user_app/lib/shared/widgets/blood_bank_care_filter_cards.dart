import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/interactive_styles.dart';
import '../../features/doctor_registration/provider/blood_bank_search_provider.dart';

class BloodBankCareFilterCards extends StatelessWidget {
  const BloodBankCareFilterCards({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BloodBankCareFilter selected;
  final ValueChanged<BloodBankCareFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: BloodBankCareFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(filter),
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: InteractiveStyles.filterCard(
                    context,
                    selected: isSelected,
                  ),
                  child: Text(
                    filter.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryDark
                          : InteractiveStyles.onSurface(context),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
