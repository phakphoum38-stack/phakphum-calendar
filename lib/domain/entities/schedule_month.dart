import 'schedule_day.dart';

class ScheduleMonth {
  ScheduleMonth({required DateTime month, required List<ScheduleDay> days})
    : month = DateTime(month.year, month.month),
      days = List.unmodifiable(days);

  factory ScheduleMonth.empty(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    final dayCount = DateTime(normalized.year, normalized.month + 1, 0).day;
    return ScheduleMonth(
      month: normalized,
      days: [
        for (var day = 1; day <= dayCount; day++)
          ScheduleDay(date: DateTime(normalized.year, normalized.month, day)),
      ],
    );
  }

  final DateTime month;
  final List<ScheduleDay> days;

  ScheduleDay? day(DateTime date) {
    if (date.year != month.year || date.month != month.month) return null;
    for (final day in days) {
      if (day.date.day == date.day) return day;
    }
    return null;
  }

  ScheduleMonth replaceDay(ScheduleDay updatedDay) {
    return ScheduleMonth(
      month: month,
      days: [
        for (final day in days)
          if (day.date.day == updatedDay.date.day) updatedDay else day,
      ],
    );
  }
}
