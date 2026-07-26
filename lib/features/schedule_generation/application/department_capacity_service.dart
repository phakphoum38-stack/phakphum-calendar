import '../../../domain/entities/schedule_day.dart';
import '../domain/department_capacity.dart';

class DepartmentCapacityService {
  const DepartmentCapacityService();

  bool hasCapacity({
    required ScheduleDay day,
    required String departmentId,
    required List<DepartmentCapacity> capacities,
  }) {
    final matching = capacities.where(
      (item) =>
          item.departmentId == departmentId && _sameDay(item.date, day.date),
    );
    if (matching.isEmpty) return true;
    final limit = matching
        .map((item) => item.maximumAssignments)
        .reduce((left, right) => left < right ? left : right);
    final assigned = day.assignments
        .where(
          (assignment) => assignment.employee.department.id == departmentId,
        )
        .length;
    return assigned < limit;
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
