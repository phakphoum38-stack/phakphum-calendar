import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../domain/dashboard_summary.dart';

/// Creates dashboard metrics from a canonical schedule without mutating it.
class DashboardSummaryService {
  const DashboardSummaryService();

  DashboardSummary build({
    required Schedule schedule,
    required DateTime now,
    required int conflictCount,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayAssignments = <ShiftAssignment>[];
    final tomorrowAssignments = <ShiftAssignment>[];
    var monthAssignmentCount = 0;
    ShiftAssignment? nextAssignment;
    DateTime? nextDate;

    for (final month in schedule.months) {
      for (final day in month.days) {
        if (day.date.year == today.year && day.date.month == today.month) {
          monthAssignmentCount += day.assignments.length;
        }
        if (_sameDate(day.date, today)) {
          todayAssignments.addAll(day.assignments);
        }
        if (_sameDate(day.date, tomorrow)) {
          tomorrowAssignments.addAll(day.assignments);
        }
        if (!day.date.isBefore(today) &&
            day.assignments.isNotEmpty &&
            (nextDate == null || day.date.isBefore(nextDate))) {
          nextDate = day.date;
          nextAssignment = day.assignments.first;
        }
      }
    }

    return DashboardSummary(
      todayAssignments: List.unmodifiable(todayAssignments),
      tomorrowAssignments: List.unmodifiable(tomorrowAssignments),
      monthAssignmentCount: monthAssignmentCount,
      conflictCount: conflictCount,
      nextAssignment: nextAssignment,
      nextAssignmentDate: nextDate,
    );
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
