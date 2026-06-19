class DoctorAvailabilitySlot {
  final int dayOfWeek;
  final int startHour;
  final bool available;

  const DoctorAvailabilitySlot({
    required this.dayOfWeek,
    required this.startHour,
    required this.available,
  });

  factory DoctorAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilitySlot(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
      startHour: (json['startHour'] as num?)?.toInt() ?? 8,
      available: json['available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startHour': startHour,
        'available': available,
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

  Set<String> get selectedSlotKeys {
    final keys = <String>{};
    for (final slot in slots) {
      if (slot.available) {
        keys.add('${slot.dayOfWeek}_${slot.startHour}');
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
