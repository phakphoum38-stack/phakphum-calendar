import '../../../domain/entities/employee.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/shift_assignment.dart';

class RuleContext {
  const RuleContext({this.schedule, this.day, this.assignment, this.employee});

  final Schedule? schedule;
  final ScheduleDay? day;
  final ShiftAssignment? assignment;
  final Employee? employee;

  Iterable<({ScheduleDay day, ShiftAssignment assignment})>
  get assignments sync* {
    final schedule = this.schedule;
    if (schedule != null) {
      for (final month in schedule.months) {
        for (final day in month.days) {
          for (final assignment in day.assignments) {
            if (employee != null && assignment.employee.id != employee!.id) {
              continue;
            }
            yield (day: day, assignment: assignment);
          }
        }
      }
    }
    if (day case final day?) {
      if (schedule == null) {
        for (final assignment in day.assignments) {
          if (employee != null && assignment.employee.id != employee!.id) {
            continue;
          }
          yield (day: day, assignment: assignment);
        }
      }
      if (assignment case final assignment?) {
        if (employee == null || assignment.employee.id == employee!.id) {
          yield (day: day, assignment: assignment);
        }
      }
    }
  }
}
