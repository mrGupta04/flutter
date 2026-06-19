import 'package:flutter/material.dart';
import '../../../../core/constants/doctor_availability_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Sunday–Saturday grid with 1-hour slots from 8 AM to 6 PM.
class WeeklyAvailabilityPicker extends StatelessWidget {
  const WeeklyAvailabilityPicker({
    super.key,
    required this.selectedSlots,
    required this.onToggle,
    this.blockedSlots = const {},
    this.weekLabel,
    this.selectedColor = AppColors.primary,
  });

  final Set<String> selectedSlots;
  final Set<String> blockedSlots;
  final void Function(int dayOfWeek, int startHour, bool selected) onToggle;
  final String? weekLabel;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final hours = DoctorAvailabilityConstants.hourSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weekLabel != null) ...[
          Text(
            weekLabel!,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          blockedSlots.isEmpty
              ? 'Tap slots when you are available. Each slot is 1 hour (8 AM – 6 PM).'
              : 'Slots already chosen for the other consultation type are hidden here.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...List.generate(7, (day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DoctorAvailabilityConstants.dayNames[day],
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hours
                      .where((hour) {
                        final key =
                            DoctorAvailabilityConstants.slotKey(day, hour);
                        final selected = selectedSlots.contains(key);
                        final blockedElsewhere =
                            !selected && blockedSlots.contains(key);
                        return !blockedElsewhere;
                      })
                      .map((hour) {
                        final key =
                            DoctorAvailabilityConstants.slotKey(day, hour);
                        final selected = selectedSlots.contains(key);
                        return FilterChip(
                          label: Text(
                            DoctorAvailabilityConstants.formatHourRange(hour),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          selected: selected,
                          onSelected: (value) => onToggle(day, hour, value),
                          selectedColor: selectedColor,
                          checkmarkColor: AppColors.white,
                          backgroundColor: AppColors.white,
                          side: BorderSide(
                            color: selected ? selectedColor : AppColors.divider,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          );
        }),
        Text(
          '${selectedSlots.length} slot(s) selected',
          style: AppTextStyles.bodySmall.copyWith(
            color: selectedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
