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
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    const slotHeight = 44.0;
                    final slotWidth = (constraints.maxWidth - spacing) / 2;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
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
                            return _AvailabilitySlotChip(
                              label: DoctorAvailabilityConstants.formatHourRange(
                                hour,
                              ),
                              selected: selected,
                              selectedColor: selectedColor,
                              width: slotWidth,
                              height: slotHeight,
                              onTap: () => onToggle(day, hour, !selected),
                            );
                          })
                          .toList(),
                    );
                  },
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

class _AvailabilitySlotChip extends StatelessWidget {
  const _AvailabilitySlotChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: selected ? selectedColor : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? selectedColor : AppColors.divider,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
