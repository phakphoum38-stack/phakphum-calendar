import 'shift_assignment.dart';

class ScheduleDay {
  ScheduleDay({
    required DateTime date,
    List<ShiftAssignment> assignments = const [],
    this.holidayName,
  }) : date = DateTime(date.year, date.month, date.day),
       assignments = List.unmodifiable(assignments);

  final DateTime date;
  final List<ShiftAssignment> assignments;
  final String? holidayName;

  bool get isHoliday =>
      holidayName != null ||
      date.weekday == DateTime.saturday ||
      date.weekday == DateTime.sunday;

  ScheduleDay copyWith({
    List<ShiftAssignment>? assignments,
    String? holidayName,
    bool clearHoliday = false,
  }) {
    return ScheduleDay(
      date: date,
      assignments: assignments ?? this.assignments,
      holidayName: clearHoliday ? null : holidayName ?? this.holidayName,
    );
  }
}
