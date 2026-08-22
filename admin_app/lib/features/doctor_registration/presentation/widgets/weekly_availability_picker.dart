import 'package:flutter/material.dart';
import '../../../../core/constants/doctor_availability_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Sunday–Saturday grid. Online consults use 20-minute chips; other types use 1 hour.
class WeeklyAvailabilityPicker extends StatelessWidget {
  const WeeklyAvailabilityPicker({
    super.key,
    required this.selectedSlots,
    required this.onToggle,
    this.blockedSlots = const {},
    this.weekLabel,
    this.helperText,
    this.selectedColor = AppColors.primary,
    this.slotMinutes = DoctorAvailabilityConstants.hourlySlotMinutes,
  });

  final Set<String> selectedSlots;
  final Set<String> blockedSlots;
  final void Function(int dayOfWeek, int startHour, bool selected, {int startMinute})
      onToggle;
  final String? weekLabel;
  final String? helperText;
  final Color selectedColor;
  final int slotMinutes;

  bool get _isOnline =>
      slotMinutes == DoctorAvailabilityConstants.onlineSlotMinutes;

  List<int> get _startMinutes => _isOnline
      ? DoctorAvailabilityConstants.onlineStartMinutes
      : const [0];

  String _key(int day, int hour, int minute) => _isOnline
      ? DoctorAvailabilityConstants.slotKey(
          day,
          hour,
          startMinute: minute,
          consultationType: 'online_consult',
        )
      : DoctorAvailabilityConstants.slotKey(day, hour);

  bool _hourBlocked(int day, int hour) {
    final hourKey = DoctorAvailabilityConstants.slotKey(day, hour);
    return blockedSlots.contains(hourKey) ||
        blockedSlots.any(
          (key) => DoctorAvailabilityConstants.hourKey(key) == hourKey,
        );
  }

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
              ? (helperText ??
                  (_isOnline
                      ? 'Tap 20-minute slots when you are available for video consults.'
                      : 'Tap slots when you are available. Each slot is 1 hour (12:00 AM – 12:00 AM, full day).'))
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
                if (_isOnline)
                  _OnlineDaySlots(
                    hours: hours,
                    selectedColor: selectedColor,
                    isSelected: (hour, minute) =>
                        selectedSlots.contains(_key(day, hour, minute)),
                    isHourBlocked: (hour) {
                      final anySelected = _startMinutes.any(
                        (minute) => selectedSlots.contains(_key(day, hour, minute)),
                      );
                      return !anySelected && _hourBlocked(day, hour);
                    },
                    onToggle: (hour, minute, selected) => onToggle(
                      day,
                      hour,
                      selected,
                      startMinute: minute,
                    ),
                  )
                else
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
                              final selected =
                                  selectedSlots.contains(_key(day, hour, 0));
                              return selected || !_hourBlocked(day, hour);
                            })
                            .map((hour) {
                              final selected =
                                  selectedSlots.contains(_key(day, hour, 0));
                              return _AvailabilitySlotChip(
                                label: DoctorAvailabilityConstants.formatSlotRange(
                                  hour,
                                  durationMinutes: slotMinutes,
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

class _OnlineDaySlots extends StatelessWidget {
  const _OnlineDaySlots({
    required this.hours,
    required this.selectedColor,
    required this.isSelected,
    required this.isHourBlocked,
    required this.onToggle,
  });

  final List<int> hours;
  final Color selectedColor;
  final bool Function(int hour, int minute) isSelected;
  final bool Function(int hour) isHourBlocked;
  final void Function(int hour, int minute, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final visibleHours = hours.where((hour) {
      final anySelected = DoctorAvailabilityConstants.onlineStartMinutes
          .any((minute) => isSelected(hour, minute));
      return anySelected || !isHourBlocked(hour);
    }).toList();

    return Column(
      children: [
        for (final hour in visibleHours) ...[
          Row(
            children: [
              for (var i = 0; i < DoctorAvailabilityConstants.onlineStartMinutes.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final minute =
                          DoctorAvailabilityConstants.onlineStartMinutes[i];
                      final selected = isSelected(hour, minute);
                      return _AvailabilitySlotChip(
                        label: DoctorAvailabilityConstants.formatSlotRange(
                          hour,
                          startMinute: minute,
                          durationMinutes:
                              DoctorAvailabilityConstants.onlineSlotMinutes,
                        ),
                        selected: selected,
                        selectedColor: selectedColor,
                        height: 40,
                        onTap: () => onToggle(hour, minute, !selected),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _AvailabilitySlotChip extends StatelessWidget {
  const _AvailabilitySlotChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.height,
    required this.onTap,
    this.width,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final double? width;
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
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
