import 'package:flutter/material.dart';
import '../../../../core/constants/doctor_availability_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum SlotScheduleAction { available, selfBusy, discard }

/// Sunday–Saturday grid. Online consults use 20-minute chips; other types use 1 hour.
class WeeklyAvailabilityPicker extends StatelessWidget {
  const WeeklyAvailabilityPicker({
    super.key,
    required this.selectedSlots,
    required this.onToggle,
    this.selfBusySlots = const {},
    this.blockedSlots = const {},
    this.weekLabel,
    this.helperText,
    this.selectedColor = AppColors.primary,
    this.slotMinutes = DoctorAvailabilityConstants.hourlySlotMinutes,
    this.enableSlotActions = false,
    this.isUpdating = false,
    this.onSlotAction,
  });

  final Set<String> selectedSlots;
  final Set<String> selfBusySlots;
  final Set<String> blockedSlots;
  final void Function(int dayOfWeek, int startHour, bool selected, {int startMinute})
      onToggle;
  final Future<void> Function(
    int dayOfWeek,
    int startHour,
    SlotScheduleAction action, {
    int startMinute,
  })? onSlotAction;
  final String? weekLabel;
  final String? helperText;
  final Color selectedColor;
  final int slotMinutes;
  final bool enableSlotActions;
  final bool isUpdating;

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

  Future<void> _onChipTap({
    required BuildContext context,
    required int day,
    required int hour,
    required int minute,
    required bool selected,
    required bool selfBusy,
  }) async {
    if (isUpdating) return;
    if (!selected) {
      onToggle(day, hour, true, startMinute: minute);
      return;
    }
    if (!enableSlotActions || onSlotAction == null) {
      onToggle(day, hour, false, startMinute: minute);
      return;
    }

    final action = await _showSlotActionsMenu(context, selfBusy: selfBusy);
    if (!context.mounted || action == null) return;
    if (action == SlotScheduleAction.discard) {
      final confirmed = await _confirmDiscard(context);
      if (!context.mounted || confirmed != true) return;
    }
    await onSlotAction!(day, hour, action, startMinute: minute);
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
                      ? (enableSlotActions
                          ? 'Tap 20-minute slots to add them. Tap a selected slot to mark Self Busy, make it available again, or discard it.'
                          : 'Tap 20-minute slots when you are available for video consults.')
                      : (enableSlotActions
                          ? 'Tap slots to add them. Tap a selected slot to mark Self Busy, make it available again, or discard it.'
                          : 'Tap slots when you are available. Each slot is 1 hour (12:00 AM – 12:00 AM, full day).')))
              : 'Slots already chosen for the other consultation type are hidden here.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        if (enableSlotActions) ...[
          const SizedBox(height: 12),
          _SlotStatusLegend(selectedColor: selectedColor),
        ],
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
                    isUpdating: isUpdating,
                    isSelected: (hour, minute) =>
                        selectedSlots.contains(_key(day, hour, minute)),
                    isSelfBusy: (hour, minute) =>
                        selfBusySlots.contains(_key(day, hour, minute)),
                    isHourBlocked: (hour) {
                      final anySelected = _startMinutes.any(
                        (minute) => selectedSlots.contains(_key(day, hour, minute)),
                      );
                      return !anySelected && _hourBlocked(day, hour);
                    },
                    onTap: (hour, minute, selected, selfBusy, chipContext) =>
                        _onChipTap(
                      context: chipContext,
                      day: day,
                      hour: hour,
                      minute: minute,
                      selected: selected,
                      selfBusy: selfBusy,
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
                              final selfBusy =
                                  selfBusySlots.contains(_key(day, hour, 0));
                              return Builder(
                                builder: (chipContext) {
                                  return _AvailabilitySlotChip(
                                    label: DoctorAvailabilityConstants.formatSlotRange(
                                      hour,
                                      durationMinutes: slotMinutes,
                                    ),
                                    selected: selected,
                                    selfBusy: selfBusy,
                                    selectedColor: selectedColor,
                                    width: slotWidth,
                                    height: slotHeight,
                                    enabled: !isUpdating,
                                    onTap: () => _onChipTap(
                                      context: chipContext,
                                      day: day,
                                      hour: hour,
                                      minute: 0,
                                      selected: selected,
                                      selfBusy: selfBusy,
                                    ),
                                  );
                                },
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

Future<SlotScheduleAction?> _showSlotActionsMenu(
  BuildContext context, {
  required bool selfBusy,
}) {
  final box = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final origin = box?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
  final size = box?.size ?? Size.zero;
  final overlaySize = overlay?.size ?? MediaQuery.sizeOf(context);

  return showMenu<SlotScheduleAction>(
    context: context,
    position: RelativeRect.fromRect(
      origin & size,
      Offset.zero & overlaySize,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: AppColors.white,
    elevation: 8,
    items: [
      if (selfBusy)
        const PopupMenuItem(
          value: SlotScheduleAction.available,
          child: _SlotActionRow(
            icon: Icons.event_available_rounded,
            label: 'Make Available',
          ),
        )
      else
        const PopupMenuItem(
          value: SlotScheduleAction.selfBusy,
          child: _SlotActionRow(
            icon: Icons.event_busy_rounded,
            label: 'Self Busy',
          ),
        ),
      const PopupMenuItem(
        value: SlotScheduleAction.discard,
        child: _SlotActionRow(
          icon: Icons.delete_outline_rounded,
          label: 'Discard Slot',
          destructive: true,
        ),
      ),
    ],
  );
}

Future<bool?> _confirmDiscard(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Discard slot'),
      content: Text(
        'Are you sure you want to discard this slot?',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
}

class _SlotActionRow extends StatelessWidget {
  const _SlotActionRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SlotStatusLegend extends StatelessWidget {
  const _SlotStatusLegend({required this.selectedColor});

  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendSwatch(color: selectedColor, label: 'Available'),
        const SizedBox(width: 16),
        const _LegendSwatch(color: AppColors.grey500, label: 'Self Busy'),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
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
    required this.isSelfBusy,
    required this.isHourBlocked,
    required this.onTap,
    required this.isUpdating,
  });

  final List<int> hours;
  final Color selectedColor;
  final bool Function(int hour, int minute) isSelected;
  final bool Function(int hour, int minute) isSelfBusy;
  final bool Function(int hour) isHourBlocked;
  final void Function(
    int hour,
    int minute,
    bool selected,
    bool selfBusy,
    BuildContext chipContext,
  ) onTap;
  final bool isUpdating;

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
                    builder: (chipContext) {
                      final minute =
                          DoctorAvailabilityConstants.onlineStartMinutes[i];
                      final selected = isSelected(hour, minute);
                      final selfBusy = isSelfBusy(hour, minute);
                      return _AvailabilitySlotChip(
                        label: DoctorAvailabilityConstants.formatSlotRange(
                          hour,
                          startMinute: minute,
                          durationMinutes:
                              DoctorAvailabilityConstants.onlineSlotMinutes,
                        ),
                        selected: selected,
                        selfBusy: selfBusy,
                        selectedColor: selectedColor,
                        height: 40,
                        enabled: !isUpdating,
                        onTap: () => onTap(
                          hour,
                          minute,
                          selected,
                          selfBusy,
                          chipContext,
                        ),
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
    this.selfBusy = false,
    this.width,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool selfBusy;
  final Color selectedColor;
  final double? width;
  final double height;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = !selected
        ? AppColors.white
        : selfBusy
            ? AppColors.grey500
            : selectedColor;
    final border = !selected
        ? AppColors.divider
        : selfBusy
            ? AppColors.grey500
            : selectedColor;
    final textColor = selected ? AppColors.white : AppColors.textPrimary;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
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
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
