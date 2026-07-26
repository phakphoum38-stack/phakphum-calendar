import '../../../domain/entities/employee.dart';
import '../../../domain/entities/schedule.dart';

/// Reads the employee directory represented by a canonical [Schedule].
///
/// Employee persistence will eventually have its own repository. Until that
/// migration is complete, this service keeps employee discovery deterministic
/// and outside presentation widgets.
class EmployeeDirectoryService {
  const EmployeeDirectoryService();

  /// Returns each employee referenced by the schedule exactly once.
  List<Employee> employees(Schedule schedule) {
    final byId = <String, Employee>{};
    for (final month in schedule.months) {
      for (final day in month.days) {
        for (final assignment in day.assignments) {
          byId.putIfAbsent(assignment.employee.id, () => assignment.employee);
        }
      }
    }
    final result = byId.values.toList()
      ..sort((left, right) {
        final department = left.department.name.compareTo(
          right.department.name,
        );
        if (department != 0) return department;
        final name = left.displayName.compareTo(right.displayName);
        if (name != 0) return name;
        return left.id.compareTo(right.id);
      });
    return List.unmodifiable(result);
  }
}
