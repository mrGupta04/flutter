/// Weekly schedule: Sunday (0) through Saturday (6), hourly 12 AM–12 AM.
class DoctorAvailabilityConstants {
  DoctorAvailabilityConstants._();

  static const int slotStartHour = 0;
  static const int slotEndHour = 23;

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

  static String formatHourRange(int startHour) {
    String fmt(int h) {
      final hour = h % 24;
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$h12:00 $suffix';
    }
    return '${fmt(startHour)} – ${fmt(startHour + 1)}';
  }
}
