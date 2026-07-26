import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../domain/department_capacity.dart';
import '../domain/employee_availability.dart';
import '../domain/schedule_conflict.dart';
import 'department_capacity_service.dart';
import 'employee_availability_service.dart';

class ConflictDetectionService {
  const ConflictDetectionService({
    this.availabilityService = const EmployeeAvailabilityService(),
    this.capacityService = const DepartmentCapacityService(),
  });

  final EmployeeAvailabilityService availabilityService;
  final DepartmentCapacityService capacityService;

  List<ScheduleConflict> detectScheduleConflicts(Schedule schedule) {
    final conflicts = <ScheduleConflict>[];
    for (final month in schedule.months) {
      for (final day in month.days) {
        for (var index = 0; index < day.assignments.length; index++) {
          for (
            var otherIndex = index + 1;
            otherIndex < day.assignments.length;
            otherIndex++
          ) {
            final left = day.assignments[index];
            final right = day.assignments[otherIndex];
            if (left.employee.id != right.employee.id) continue;
            if (left.shift.id == right.shift.id) {
              conflicts.add(
                ScheduleConflict(
                  type: ScheduleConflictType.duplicateAssignment,
                  message: 'Duplicate shift assignment.',
                  severity: ScheduleConflictSeverity.error,
                  employeeId: left.employee.id,
                  date: day.date,
                ),
              );
            } else if (_overlaps(day, left, right)) {
              conflicts.add(
                ScheduleConflict(
                  type: ScheduleConflictType.overlappingShift,
                  message: 'Overlapping shift assignment.',
                  severity: ScheduleConflictSeverity.error,
                  employeeId: left.employee.id,
                  date: day.date,
                ),
              );
            }
          }
        }
      }
    }
    return conflicts;
  }

  List<ScheduleConflict> validateProposedAssignment({
    required ScheduleDay day,
    required ShiftAssignment assignment,
    List<EmployeeAvailability> availability = const [],
    List<DepartmentCapacity> capacities = const [],
  }) {
    final conflicts = <ScheduleConflict>[];
    if (!availabilityService.isAvailable(
      assignment: assignment,
      date: day.date,
      availability: availability,
    )) {
      conflicts.add(
        ScheduleConflict(
          type: ScheduleConflictType.unavailableEmployee,
          message: 'Employee is unavailable for this shift.',
          severity: ScheduleConflictSeverity.error,
          employeeId: assignment.employee.id,
          date: day.date,
        ),
      );
    }
    if (!capacityService.hasCapacity(
      day: day,
      departmentId: assignment.employee.department.id,
      capacities: capacities,
    )) {
      conflicts.add(
        ScheduleConflict(
          type: ScheduleConflictType.departmentCapacity,
          message: 'Department capacity has been reached.',
          severity: ScheduleConflictSeverity.error,
          employeeId: assignment.employee.id,
          date: day.date,
        ),
      );
    }
    for (final existing in day.assignments) {
      if (existing.employee.id != assignment.employee.id) continue;
      if (existing.shift.id == assignment.shift.id) {
        conflicts.add(
          ScheduleConflict(
            type: ScheduleConflictType.duplicateAssignment,
            message: 'Employee already has this shift.',
            severity: ScheduleConflictSeverity.error,
            employeeId: assignment.employee.id,
            date: day.date,
          ),
        );
      } else if (_overlaps(day, existing, assignment)) {
        conflicts.add(
          ScheduleConflict(
            type: ScheduleConflictType.overlappingShift,
            message: 'Employee has an overlapping shift.',
            severity: ScheduleConflictSeverity.error,
            employeeId: assignment.employee.id,
            date: day.date,
          ),
        );
      }
    }
    return conflicts;
  }

  bool _overlaps(ScheduleDay day, ShiftAssignment left, ShiftAssignment right) {
    final leftRange = _range(day, left);
    final rightRange = _range(day, right);
    return leftRange.$1.isBefore(rightRange.$2) &&
        rightRange.$1.isBefore(leftRange.$2);
  }

  (DateTime, DateTime) _range(ScheduleDay day, ShiftAssignment assignment) {
    final start = day.date.add(assignment.shift.startTime);
    var end = day.date.add(assignment.shift.endTime);
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return (start, end);
  }
}
