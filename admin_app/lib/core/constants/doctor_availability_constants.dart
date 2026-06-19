/// Weekly schedule: Sunday (0) through Saturday (6), hourly 8 AM–6 PM.
class DoctorAvailabilityConstants {
  DoctorAvailabilityConstants._();

  static const int slotStartHour = 8;
  static const int slotEndHour = 17;

  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> dayShortNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static List<int> get hourSlots =>
      List.generate(slotEndHour - slotStartHour + 1, (i) => slotStartHour + i);

  static String slotKey(int dayOfWeek, int startHour) => '${dayOfWeek}_$startHour';

  static String formatHourRange(int startHour) {
    String fmt(int h) {
      final suffix = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:00 $suffix';
    }
    return '${fmt(startHour)} – ${fmt(startHour + 1)}';
  }

  static List<Map<String, dynamic>> buildSlotPayload(Set<String> selectedKeys) {
    final slots = <Map<String, dynamic>>[];
    for (var day = 0; day <= 6; day++) {
      for (final hour in hourSlots) {
        slots.add({
          'dayOfWeek': day,
          'startHour': hour,
          'available': selectedKeys.contains(slotKey(day, hour)),
        });
      }
    }
    return slots;
  }
}
