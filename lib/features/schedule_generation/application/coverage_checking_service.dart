import '../../../domain/entities/schedule.dart';
import '../domain/coverage_requirement.dart';

class CoverageCheckingService {
  const CoverageCheckingService();

  int assignedCount(Schedule schedule, CoverageRequirement requirement) {
    final day = schedule.month(requirement.date)?.day(requirement.date);
    if (day == null) return 0;
    return day.assignments
        .where(
          (assignment) =>
              assignment.employee.department.id == requirement.departmentId &&
              assignment.shift.id == requirement.shiftTypeId &&
              (requirement.location == null ||
                  assignment.location == requirement.location),
        )
        .length;
  }

  List<CoverageRequirement> uncovered(
    Schedule schedule,
    List<CoverageRequirement> requirements,
  ) {
    return requirements
        .where(
          (requirement) =>
              assignedCount(schedule, requirement) <
              requirement.requiredEmployees,
        )
        .toList(growable: false);
  }
}
