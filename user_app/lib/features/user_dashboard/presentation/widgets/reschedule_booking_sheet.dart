import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/bookable_slot_model.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../data/repositories/booking_lifecycle_repository.dart';
import '../../../../data/repositories/nurse_home_visit_repository.dart';
import '../../../../data/repositories/online_consult_repository.dart';
import '../../../../shared/widgets/bookable_slots_section.dart';

Future<bool> showRescheduleBookingSheet(
  BuildContext context, {
  required PatientBookingModel booking,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _RescheduleSheet(booking: booking),
  );
  return result == true;
}

class _RescheduleSheet extends ConsumerStatefulWidget {
  const _RescheduleSheet({required this.booking});

  final PatientBookingModel booking;

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  BookableSlotsResponse? _slots;
  BookableSlot? _selected;
  String? _selectedDateKey;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.booking.isNurseVisit) {
        final repo = NurseHomeVisitRepository();
        final res = await repo.getBookableSlots(
          nurseId: widget.booking.providerId,
        );
        if (!res.success || res.data == null) {
          throw Exception(res.error ?? 'Could not load slots');
        }
        setState(() {
          _slots = res.data;
          _loading = false;
        });
      } else {
        final repo = OnlineConsultRepository();
        final res = await repo.getBookableSlots(
          doctorId: widget.booking.providerId,
          consultationType: widget.booking.consultationType,
        );
        if (!res.success || res.data == null) {
          throw Exception(res.error ?? 'Could not load slots');
        }
        setState(() {
          _slots = res.data;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    final slot = _selected;
    if (slot == null || _saving) return;
    setState(() => _saving = true);
    try {
      await BookingLifecycleRepository().reschedule(
        widget.booking.id,
        slotStart: slot.slotStart,
        slotEnd: slot.slotEnd,
        dayOfWeek: slot.dayOfWeek,
        startHour: slot.startHour,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.85;
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Reschedule visit',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Current: ${widget.booking.label}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : (_slots == null || _slots!.slots.isEmpty)
                        ? const Center(child: Text('No open slots available'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: BookableSlotsSection(
                              slotsData: _slots!,
                              selectedSlot: _selected,
                              selectedDateKey: _selectedDateKey,
                              onDateSelected: (dateKey) {
                                setState(() {
                                  _selectedDateKey = dateKey;
                                  if (_selected?.dateKey != dateKey) {
                                    _selected = null;
                                  }
                                });
                              },
                              onSlotSelected: (slot) {
                                setState(() => _selected = slot);
                              },
                            ),
                          ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _selected == null || _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm new time'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
