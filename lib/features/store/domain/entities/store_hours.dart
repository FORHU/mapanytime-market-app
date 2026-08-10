import 'package:intl/intl.dart';

/// One day's schedule for a store, as returned by `GET /stores/:id`.
///
/// [dayOfWeek] follows the backend's Prisma convention: 0=Sun … 6=Sat.
class StoreDayHours {
  const StoreDayHours({
    required this.dayOfWeek,
    required this.isClosed,
    this.openMinutes,
    this.closeMinutes,
  });

  final int dayOfWeek;
  final bool isClosed;

  /// Minutes since midnight, e.g. 480 → 08:00.
  final int? openMinutes;
  final int? closeMinutes;
}

extension StoreHoursX on List<StoreDayHours> {
  /// Whether the store is open right now, per the local device clock.
  /// Defaults to `true` when hours are unknown so the UI doesn't guess closed.
  bool isOpenNow() {
    if (isEmpty) return true;
    final now = DateTime.now();
    final dow = now.weekday % 7; // DateTime: 1=Mon..7=Sun -> 0=Sun..6=Sat
    final day = today(dow: dow);
    if (day == null) return true;
    if (day.isClosed) return false;
    final open = day.openMinutes;
    final close = day.closeMinutes;
    if (open == null || close == null) return true;
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= open && nowMinutes < close;
  }

  /// Today's entry, or `null` if hours weren't provided for today.
  StoreDayHours? today({int? dow}) {
    final target = dow ?? (DateTime.now().weekday % 7);
    for (final day in this) {
      if (day.dayOfWeek == target) return day;
    }
    return null;
  }

  /// Human-readable range for [day], e.g. "9:00 AM – 9:00 PM", or "Closed".
  String formatted(StoreDayHours day) {
    if (day.isClosed) return 'Closed';
    final open = day.openMinutes;
    final close = day.closeMinutes;
    if (open == null || close == null) return 'Closed';
    return '${_formatMinutes(open)} – ${_formatMinutes(close)}';
  }
}

String _formatMinutes(int minutesSinceMidnight) {
  final time = DateTime(2000).add(Duration(minutes: minutesSinceMidnight));
  return DateFormat.jm().format(time);
}

const List<String> weekdayLabels = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
