import '../../core/constants/doctor_availability_constants.dart';

class DoctorAvailabilitySlot {
  final int dayOfWeek;
  final int startHour;
  final int startMinute;
  final bool available;
  final String status;

  const DoctorAvailabilitySlot({
    required this.dayOfWeek,
    required this.startHour,
    this.startMinute = 0,
    required this.available,
    this.status = DoctorAvailabilityConstants.statusDiscarded,
  });

  bool get isSelfBusy =>
      status.toUpperCase() == DoctorAvailabilityConstants.statusSelfBusy;

  bool get isOnSchedule {
    switch (status.toUpperCase()) {
      case DoctorAvailabilityConstants.statusAvailable:
      case DoctorAvailabilityConstants.statusSelfBusy:
      case DoctorAvailabilityConstants.statusBooked:
        return true;
      case DoctorAvailabilityConstants.statusDiscarded:
        return false;
      default:
        return available;
    }
  }

  factory DoctorAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    final available = json['available'] as bool? ?? false;
    final rawStatus = (json['status'] as String?)?.toUpperCase();
    return DoctorAvailabilitySlot(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
      startHour: (json['startHour'] as num?)?.toInt() ?? 8,
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
      available: available,
      status: rawStatus ??
          (available
              ? DoctorAvailabilityConstants.statusAvailable
              : DoctorAvailabilityConstants.statusDiscarded),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startHour': startHour,
        'startMinute': startMinute,
        'available': available,
        'status': status,
      };
}

class DoctorAvailabilityModel {
  final String? doctorId;
  final String? consultationType;
  final DateTime? weekStartDate;
  final DateTime? weekEndDate;
  final List<DoctorAvailabilitySlot> slots;
  final int availableSlotCount;
  final bool needsUpdate;
  final String? reminderMessage;
  final bool isExpired;

  const DoctorAvailabilityModel({
    this.doctorId,
    this.consultationType,
    this.weekStartDate,
    this.weekEndDate,
    this.slots = const [],
    this.availableSlotCount = 0,
    this.needsUpdate = false,
    this.reminderMessage,
    this.isExpired = false,
  });

  Set<String> get selectedSlotKeys => _keysWhere((slot) => slot.isOnSchedule);

  Set<String> get selfBusySlotKeys => _keysWhere((slot) => slot.isSelfBusy);

  Set<String> _keysWhere(bool Function(DoctorAvailabilitySlot slot) include) {
    final keys = <String>{};
    final online = consultationType == 'online_consult';
    final usesMinutes =
        slots.any((slot) => slot.startMinute == 20 || slot.startMinute == 40);

    for (final slot in slots) {
      if (!include(slot)) continue;
      if (online && !usesMinutes) {
        for (final minute in DoctorAvailabilityConstants.onlineStartMinutes) {
          keys.add(
            DoctorAvailabilityConstants.slotKey(
              slot.dayOfWeek,
              slot.startHour,
              startMinute: minute,
              consultationType: 'online_consult',
            ),
          );
        }
      } else {
        keys.add(
          DoctorAvailabilityConstants.slotKey(
            slot.dayOfWeek,
            slot.startHour,
            startMinute: slot.startMinute,
            consultationType: consultationType,
          ),
        );
      }
    }
    return keys;
  }

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final slotList = (json['slots'] as List? ?? [])
        .map((e) => DoctorAvailabilitySlot.fromJson(e as Map<String, dynamic>))
        .toList();

    return DoctorAvailabilityModel(
      doctorId: json['doctorId'] as String?,
      consultationType: json['consultationType'] as String?,
      weekStartDate: _parseDate(json['weekStartDate']),
      weekEndDate: _parseDate(json['weekEndDate']),
      slots: slotList,
      availableSlotCount: (json['availableSlotCount'] as num?)?.toInt() ??
          slotList.where((s) => s.available).length,
      needsUpdate: json['needsUpdate'] as bool? ?? false,
      reminderMessage: json['reminderMessage'] as String?,
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSaveJson({DateTime? weekStart}) => {
        if (weekStart != null) 'weekStartDate': weekStart.toIso8601String(),
        'slots': slots.map((s) => s.toJson()).toList(),
      };
}

class AvailabilityReminder {
  final bool needsUpdate;
  final String? message;
  final DateTime? suggestedWeekStart;
  final DateTime? suggestedWeekEnd;

  const AvailabilityReminder({
    required this.needsUpdate,
    this.message,
    this.suggestedWeekStart,
    this.suggestedWeekEnd,
  });

  factory AvailabilityReminder.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AvailabilityReminder(needsUpdate: false);
    }
    return AvailabilityReminder(
      needsUpdate: json['needsUpdate'] as bool? ?? false,
      message: json['message'] as String?,
      suggestedWeekStart: _parseDate(json['suggestedWeekStart']),
      suggestedWeekEnd: _parseDate(json['suggestedWeekEnd']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
