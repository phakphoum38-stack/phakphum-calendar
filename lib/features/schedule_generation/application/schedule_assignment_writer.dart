import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/schedule_month.dart';
import '../../../domain/entities/shift_assignment.dart';

class ScheduleAssignmentWriter {
  const ScheduleAssignmentWriter();

  Schedule add({
    required Schedule schedule,
    required DateTime date,
    required ShiftAssignment assignment,
  }) {
    final month = schedule.month(date) ?? ScheduleMonth.empty(date);
    final day = month.day(date) ?? ScheduleDay(date: date);
    final updatedDay = day.copyWith(
      assignments: [...day.assignments, assignment],
    );
    return schedule.replaceMonth(month.replaceDay(updatedDay));
  }
}
