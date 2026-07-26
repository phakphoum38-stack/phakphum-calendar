import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../domain/coverage_requirement.dart';
import '../domain/department_capacity.dart';
import '../domain/employee_availability.dart';
import '../domain/generation_request.dart';
import '../domain/generation_result.dart';
import 'auto_assignment_service.dart';
import 'manual_schedule_service.dart';

class ScheduleGenerator {
  const ScheduleGenerator({
    this.manualService = const ManualScheduleService(),
    this.autoService = const AutoAssignmentService(),
  });

  final ManualScheduleService manualService;
  final AutoAssignmentService autoService;

  GenerationResult manualAssignment({
    required Schedule schedule,
    required DateTime date,
    required ShiftAssignment assignment,
    List<EmployeeAvailability> availability = const [],
    List<DepartmentCapacity> capacities = const [],
    List<CoverageRequirement> coverageRequirements = const [],
  }) {
    return manualService.assign(
      schedule: schedule,
      date: date,
      assignment: assignment,
      availability: availability,
      capacities: capacities,
      coverageRequirements: coverageRequirements,
    );
  }

  GenerationResult autoAssign(GenerationRequest request) =>
      autoService.generate(request);
}
