import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Gender selection as radio buttons (replaces dropdown in registration forms).
class GenderRadioField extends StatelessWidget {
  const GenderRadioField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
    this.label = 'Gender',
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: (_) => validator?.call(value),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: options.map((option) {
                final isSelected = value == option;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    field.didChange(option);
                    onChanged(option);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: option,
                          groupValue: value,
                          onChanged: (v) {
                            field.didChange(v);
                            onChanged(v);
                          },
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text(
                          option,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Text(
                field.errorText!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
