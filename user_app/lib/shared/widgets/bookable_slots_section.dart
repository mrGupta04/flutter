import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validation_utils.dart';
import '../../data/models/bookable_slot_model.dart';

/// Day + hour chips for booking from doctor weekly availability.
class BookableSlotsSection extends StatelessWidget {
  const BookableSlotsSection({
    super.key,
    required this.slotsData,
    required this.selectedSlot,
    required this.selectedDateKey,
    required this.onDateSelected,
    required this.onSlotSelected,
    this.emptyMessage,
    this.isSlotSelectionBusy = false,
  });

  final BookableSlotsResponse slotsData;
  final BookableSlot? selectedSlot;
  final String? selectedDateKey;
  final ValueChanged<String> onDateSelected;
  final ValueChanged<BookableSlot?> onSlotSelected;
  final String? emptyMessage;
  final bool isSlotSelectionBusy;

  @override
  Widget build(BuildContext context) {
    if (slotsData.slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppDecorations.borderRadiusMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              'No appointment slots',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              slotsData.message ??
                  emptyMessage ??
                  'No open slots right now. Try another doctor or check back later.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final slotsByDate = <String, List<BookableSlot>>{};
    for (final slot in slotsData.slots) {
      slotsByDate.putIfAbsent(slot.dateKey, () => []).add(slot);
    }
    for (final entry in slotsByDate.entries) {
      entry.value.sort((a, b) => a.slotStart.compareTo(b.slotStart));
    }

    final dateKeys = slotsByDate.keys.toList()..sort();
    final activeDateKey =
        selectedDateKey != null && dateKeys.contains(selectedDateKey)
            ? selectedDateKey!
            : dateKeys.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (slotsData.weekStartDate != null && slotsData.weekEndDate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Available ${FormattingUtils.formatDate(slotsData.weekStartDate!.toLocal())} – '
              '${FormattingUtils.formatDate(slotsData.weekEndDate!.toLocal())}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${slotsData.slots.length} upcoming slot${slotsData.slots.length == 1 ? '' : 's'} '
            'across ${dateKeys.length} day${dateKeys.length == 1 ? '' : 's'}. '
            'Past times are not shown.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dateKeys.map((dateKey) {
              final isSelected = dateKey == activeDateKey;
              final count = slotsByDate[dateKey]?.length ?? 0;
              final sample = slotsByDate[dateKey]!.first.localSlotStart;
              final dayLabel = DateFormat('EEE, d MMM').format(sample);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$dayLabel ($count)'),
                  selected: isSelected,
                  onSelected: (_) => onDateSelected(dateKey),
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        ...dateKeys.map((dateKey) {
          final daySlots = slotsByDate[dateKey] ?? const <BookableSlot>[];
          final sample = daySlots.first.localSlotStart;
          final dayHeading = DateFormat('EEEE, d MMMM').format(sample);
          final highlightDay = dateKey == activeDateKey;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dayHeading,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: highlightDay
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: daySlots.map((slot) {
                    final isSelected = selectedSlot?.slotKey == slot.slotKey;
                    final timeLabel = _slotTimeLabel(slot);
                    return FilterChip(
                      label: Text(
                        timeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: isSlotSelectionBusy
                          ? null
                          : (value) {
                              onDateSelected(dateKey);
                              onSlotSelected(value ? slot : null);
                            },
                      selectedColor: AppColors.primary,
                      checkmarkColor: AppColors.white,
                      backgroundColor: AppColors.white,
                      side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        if (selectedSlot != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppDecorations.borderRadiusMd,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedSlot!.label.isNotEmpty
                        ? selectedSlot!.label
                        : '${FormattingUtils.formatDateWithDay(selectedSlot!.localSlotStart)} • '
                            '${_slotTimeLabel(selectedSlot!)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _slotTimeLabel(BookableSlot slot) {
    if (slot.label.contains('•')) {
      final parts = slot.label.split('•');
      if (parts.length > 1) {
        return parts.last.trim();
      }
    }
    return '${FormattingUtils.formatTime(slot.localSlotStart)} – '
        '${FormattingUtils.formatTime(slot.localSlotEnd)}';
  }
}
