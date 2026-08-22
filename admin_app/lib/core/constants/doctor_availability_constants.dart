/// Weekly schedule: Sunday (0) through Saturday (6).
/// Online consults are 20-minute windows; clinic and home visits are 1 hour.
class DoctorAvailabilityConstants {
  DoctorAvailabilityConstants._();

  static const int slotStartHour = 0;
  static const int slotEndHour = 23;
  static const int onlineSlotMinutes = 20;
  static const int hourlySlotMinutes = 60;
  static const List<int> onlineStartMinutes = [0, 20, 40];

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

  static bool isOnlineConsult(String? consultationType) =>
      consultationType == 'online_consult';

  static int slotMinutesFor(String? consultationType) =>
      isOnlineConsult(consultationType)
          ? onlineSlotMinutes
          : hourlySlotMinutes;

  static List<int> startMinutesFor(String? consultationType) =>
      isOnlineConsult(consultationType) ? onlineStartMinutes : const [0];

  static String slotKey(
    int dayOfWeek,
    int startHour, {
    int startMinute = 0,
    String? consultationType,
  }) {
    if (isOnlineConsult(consultationType)) {
      return '${dayOfWeek}_${startHour}_$startMinute';
    }
    return '${dayOfWeek}_$startHour';
  }

  static String hourKey(String slotKey) {
    final parts = slotKey.split('_');
    if (parts.length >= 2) return '${parts[0]}_${parts[1]}';
    return slotKey;
  }

  static Set<String> hourKeys(Iterable<String> keys) =>
      keys.map(hourKey).toSet();

  static String formatSlotRange(
    int startHour, {
    int startMinute = 0,
    int durationMinutes = 60,
  }) {
    String fmt(int totalMinutes) {
      final normalized = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60);
      final hour = normalized ~/ 60;
      final minute = normalized % 60;
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      final mm = minute.toString().padLeft(2, '0');
      return '$h12:$mm $suffix';
    }

    final startTotal = startHour * 60 + startMinute;
    return '${fmt(startTotal)} – ${fmt(startTotal + durationMinutes)}';
  }

  static String formatHourRange(int startHour) =>
      formatSlotRange(startHour, durationMinutes: hourlySlotMinutes);

  static List<Map<String, dynamic>> buildSlotPayload(
    Set<String> selectedKeys, {
    String consultationType = 'visit_site',
  }) {
    final online = isOnlineConsult(consultationType);
    final slots = <Map<String, dynamic>>[];
    for (var day = 0; day <= 6; day++) {
      for (final hour in hourSlots) {
        if (online) {
          for (final minute in onlineStartMinutes) {
            slots.add({
              'dayOfWeek': day,
              'startHour': hour,
              'startMinute': minute,
              'available': selectedKeys.contains(
                slotKey(
                  day,
                  hour,
                  startMinute: minute,
                  consultationType: consultationType,
                ),
              ),
            });
          }
        } else {
          slots.add({
            'dayOfWeek': day,
            'startHour': hour,
            'startMinute': 0,
            'available': selectedKeys.contains(slotKey(day, hour)),
          });
        }
      }
    }
    return slots;
  }
}
