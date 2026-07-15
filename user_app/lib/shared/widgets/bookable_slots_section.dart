import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/bookable_slot_model.dart';

enum _SlotPeriod { morning, afternoon, evening, night }

extension _SlotPeriodX on _SlotPeriod {
  String get label => switch (this) {
        _SlotPeriod.morning => 'Morning',
        _SlotPeriod.afternoon => 'Afternoon',
        _SlotPeriod.evening => 'Evening',
        _SlotPeriod.night => 'Night',
      };

  IconData get icon => switch (this) {
        _SlotPeriod.morning => Icons.wb_twilight_rounded,
        _SlotPeriod.afternoon => Icons.wb_sunny_rounded,
        _SlotPeriod.evening => Icons.wb_twilight_outlined,
        _SlotPeriod.night => Icons.nights_stay_rounded,
      };

  static _SlotPeriod fromHour(int hour) {
    if (hour >= 5 && hour < 12) return _SlotPeriod.morning;
    if (hour >= 12 && hour < 17) return _SlotPeriod.afternoon;
    if (hour >= 17 && hour < 21) return _SlotPeriod.evening;
    return _SlotPeriod.night;
  }
}

/// Preferred-slot picker for doctor and nurse bookings.
class BookableSlotsSection extends StatefulWidget {
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
  State<BookableSlotsSection> createState() => _BookableSlotsSectionState();
}

class _BookableSlotsSectionState extends State<BookableSlotsSection> {
  static const _collapsedSlotCount = 6;

  final Set<_SlotPeriod> _collapsedPeriods = {};
  final Set<_SlotPeriod> _showAllForPeriod = {};

  @override
  void didUpdateWidget(covariant BookableSlotsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDateKey != widget.selectedDateKey ||
        oldWidget.slotsData != widget.slotsData) {
      _showAllForPeriod.clear();
      _collapsedPeriods.clear();
    }
  }

  Map<String, List<BookableSlot>> get _slotsByDate {
    final map = <String, List<BookableSlot>>{};
    for (final slot in widget.slotsData.slots) {
      map.putIfAbsent(slot.dateKey, () => []).add(slot);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.slotStart.compareTo(b.slotStart));
    }
    return map;
  }

  String? _activeDateKey(List<String> dateKeys) {
    if (dateKeys.isEmpty) return null;
    if (widget.selectedDateKey != null &&
        dateKeys.contains(widget.selectedDateKey)) {
      return widget.selectedDateKey;
    }
    return dateKeys.first;
  }

  String _dayCaption(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE').format(date);
  }

  String _slotTimeLabel(BookableSlot slot) {
    return DateFormat('hh:mm a').format(slot.localSlotStart);
  }

  Map<_SlotPeriod, List<BookableSlot>> _groupByPeriod(
    List<BookableSlot> slots,
  ) {
    final grouped = <_SlotPeriod, List<BookableSlot>>{};
    for (final slot in slots) {
      final period = _SlotPeriodX.fromHour(slot.localSlotStart.hour);
      grouped.putIfAbsent(period, () => []).add(slot);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slotsData.slots.isEmpty) {
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
              widget.slotsData.message ??
                  widget.emptyMessage ??
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

    final slotsByDate = _slotsByDate;
    final dateKeys = slotsByDate.keys.toList()..sort();
    final activeDateKey = _activeDateKey(dateKeys)!;

    final daySlots = slotsByDate[activeDateKey] ?? const <BookableSlot>[];
    final grouped = _groupByPeriod(daySlots);
    final orderedPeriods = _SlotPeriod.values
        .where((p) => grouped.containsKey(p) && grouped[p]!.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select your preferred slot',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _DateStrip(
          dateKeys: dateKeys,
          slotsByDate: slotsByDate,
          activeDateKey: activeDateKey,
          dayCaption: _dayCaption,
          onDateSelected: (dateKey) {
            setState(() {
              _showAllForPeriod.clear();
              _collapsedPeriods.clear();
            });
            widget.onDateSelected(dateKey);
            if (widget.selectedSlot?.dateKey != dateKey) {
              widget.onSlotSelected(null);
            }
          },
        ),
        const SizedBox(height: 18),
        for (final period in orderedPeriods) ...[
          _PeriodSection(
            period: period,
            slots: grouped[period]!,
            selectedSlot: widget.selectedSlot,
            isExpanded: !_collapsedPeriods.contains(period),
            showAll: _showAllForPeriod.contains(period),
            collapsedCount: _collapsedSlotCount,
            isBusy: widget.isSlotSelectionBusy,
            timeLabelBuilder: _slotTimeLabel,
            onToggleExpanded: () {
              setState(() {
                if (_collapsedPeriods.contains(period)) {
                  _collapsedPeriods.remove(period);
                } else {
                  _collapsedPeriods.add(period);
                }
              });
            },
            onToggleShowAll: () {
              setState(() {
                if (_showAllForPeriod.contains(period)) {
                  _showAllForPeriod.remove(period);
                } else {
                  _showAllForPeriod.add(period);
                }
              });
            },
            onSlotTap: (slot) {
              widget.onDateSelected(activeDateKey);
              final isSelected = widget.selectedSlot?.slotKey == slot.slotKey &&
                  widget.selectedSlot?.dateKey == slot.dateKey;
              widget.onSlotSelected(isSelected ? null : slot);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.dateKeys,
    required this.slotsByDate,
    required this.activeDateKey,
    required this.dayCaption,
    required this.onDateSelected,
  });

  final List<String> dateKeys;
  final Map<String, List<BookableSlot>> slotsByDate;
  final String activeDateKey;
  final String Function(DateTime date) dayCaption;
  final ValueChanged<String> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final activeDate = slotsByDate[activeDateKey]!.first.localSlotStart;
    final monthLabel = DateFormat('MMM').format(activeDate).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              monthLabel,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5B6B7C),
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dateKeys.length,
              separatorBuilder: (context, index) => VerticalDivider(
                width: 16,
                thickness: 1,
                indent: 10,
                endIndent: 10,
                color: AppColors.grey200,
              ),
              itemBuilder: (context, index) {
                final dateKey = dateKeys[index];
                final sample = slotsByDate[dateKey]!.first.localSlotStart;
                final selected = dateKey == activeDateKey;
                final caption = dayCaption(sample);
                final dayNum = DateFormat('d').format(sample);

                return InkWell(
                  onTap: () => onDateSelected(dateKey),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 14 : 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2F343A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          caption,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.grey500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayNum,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({
    required this.period,
    required this.slots,
    required this.selectedSlot,
    required this.isExpanded,
    required this.showAll,
    required this.collapsedCount,
    required this.isBusy,
    required this.timeLabelBuilder,
    required this.onToggleExpanded,
    required this.onToggleShowAll,
    required this.onSlotTap,
  });

  final _SlotPeriod period;
  final List<BookableSlot> slots;
  final BookableSlot? selectedSlot;
  final bool isExpanded;
  final bool showAll;
  final int collapsedCount;
  final bool isBusy;
  final String Function(BookableSlot slot) timeLabelBuilder;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleShowAll;
  final ValueChanged<BookableSlot> onSlotTap;

  @override
  Widget build(BuildContext context) {
    final visibleSlots =
        showAll || slots.length <= collapsedCount
            ? slots
            : slots.take(collapsedCount).toList();
    final hasMore = slots.length > collapsedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  period.icon,
                  size: 18,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  period.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${slots.length})',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleSlots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.35,
            ),
            itemBuilder: (context, index) {
              final slot = visibleSlots[index];
              final isSelected = selectedSlot?.slotKey == slot.slotKey &&
                  selectedSlot?.dateKey == slot.dateKey;
              return _TimeSlotChip(
                label: timeLabelBuilder(slot),
                selected: isSelected,
                enabled: !isBusy,
                onTap: () => onSlotTap(slot),
              );
            },
          ),
          if (hasMore) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: onToggleShowAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showAll ? 'View Less Slots' : 'View All Slots',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      showAll
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.grey200,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textPrimary,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
